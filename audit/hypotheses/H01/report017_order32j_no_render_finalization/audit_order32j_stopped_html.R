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
  "audit/hypotheses/H01/report017_order32j_no_render_finalization"
)
write_csv <- function(object, filename) {
  write.csv(
    object,
    file.path(evidence_dir, filename),
    row.names = FALSE,
    na = ""
  )
}
clean_text <- function(node) {
  trimws(gsub("[[:space:]]+", " ", html_text2(node)))
}
outside_source_modal <- function(nodes) {
  if (!length(nodes)) {
    return(logical())
  }
  !vapply(nodes, function(node) {
    length(xml_find_all(
      node,
      "ancestor::*[@id='quarto-embedded-source-code-modal']"
    )) > 0L
  }, logical(1))
}
read_bytes <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, what = "raw", n = as.numeric(file.info(path)$size))
}

html_relative <-
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html"
qmd_relative <- "audit/hypotheses/H01/H01_analysis_preparation.qmd"
build_qmd_relative <- paste0(
  "_build/nathealth/audit/hypotheses/H01/",
  "H01_analysis_preparation.qmd"
)
result_html_relative <- "_build/nathealth/notebooks/hypotheses/H01.html"
build_root <- normalizePath("_build/nathealth", winslash = "/", mustWork = TRUE)
html_path <- file.path(root, html_relative)
doc <- read_html(html_path)
main <- html_elements(doc, "main#quarto-document-content")
stopifnot(length(main) == 1L)
main <- main[[1L]]
main_text <- clean_text(main)

qmd_lines <- readLines(qmd_relative, warn = FALSE, encoding = "UTF-8")
source_table_ids <- sub(
  "^.*#\\| label: (tbl-h01-[a-z0-9-]+).*$",
  "\\1",
  qmd_lines[grepl("#\\| label: tbl-h01-", qmd_lines)]
)
source_figure_ids <- sub(
  "^.*#\\| label: (fig-h01-[a-z0-9-]+).*$",
  "\\1",
  qmd_lines[grepl("#\\| label: fig-h01-", qmd_lines)]
)

table_endpoints <- html_elements(main, '.quarto-float[id^="tbl-h01-prep-"]')
table_endpoints <- table_endpoints[outside_source_modal(table_endpoints)]
table_ids <- html_attr(table_endpoints, "id")
table_audit <- do.call(rbind, lapply(seq_along(table_endpoints), function(index) {
  endpoint <- table_endpoints[[index]]
  tables <- html_elements(endpoint, "table.gt_table")
  captions <- html_elements(endpoint, "figcaption.quarto-float-caption")
  data.frame(
    endpoint_order = index,
    table_id = table_ids[[index]],
    native_gt_count = length(tables),
    caption_count = length(captions),
    thead_count = length(html_elements(endpoint, "table.gt_table thead")),
    tbody_count = length(html_elements(endpoint, "table.gt_table tbody")),
    body_rows = length(html_elements(endpoint, "table.gt_table tbody tr")),
    body_cells = length(html_elements(endpoint, "table.gt_table tbody td")),
    pass = length(tables) == 1L && length(captions) == 1L &&
      nzchar(clean_text(captions[[1L]])) &&
      length(html_elements(endpoint, "table.gt_table thead")) == 1L &&
      length(html_elements(endpoint, "table.gt_table tbody")) == 1L &&
      length(html_elements(endpoint, "table.gt_table tbody tr")) > 0L &&
      length(html_elements(endpoint, "table.gt_table tbody td")) > 0L,
    stringsAsFactors = FALSE
  )
}))
write_csv(table_audit, "order32j_stopped_table_endpoint_audit.csv")

figure_endpoints <- html_elements(main, '.quarto-float[id^="fig-h01-prep-"]')
figure_endpoints <- figure_endpoints[outside_source_modal(figure_endpoints)]
figure_ids <- html_attr(figure_endpoints, "id")
figure_audit <- do.call(rbind, lapply(seq_along(figure_endpoints), function(index) {
  endpoint <- figure_endpoints[[index]]
  images <- html_elements(endpoint, "img")
  captions <- html_elements(endpoint, "figcaption.quarto-float-caption")
  image_src <- if (length(images)) html_attr(images[[1L]], "src") else ""
  image_alt <- if (length(images)) html_attr(images[[1L]], "alt") else ""
  resolved <- if (nzchar(image_src)) {
    normalizePath(
      file.path(dirname(html_path), URLdecode(image_src)),
      winslash = "/",
      mustWork = FALSE
    )
  } else {
    ""
  }
  data.frame(
    endpoint_order = index,
    figure_id = figure_ids[[index]],
    image_count = length(images),
    caption_count = length(captions),
    image_src = image_src,
    image_alt = image_alt,
    resolved_path = resolved,
    source_exists = nzchar(resolved) && file.exists(resolved),
    pass = length(images) == 1L && length(captions) == 1L &&
      nzchar(clean_text(captions[[1L]])) && !is.na(image_alt) &&
      nzchar(image_alt) && nzchar(resolved) && file.exists(resolved),
    stringsAsFactors = FALSE
  )
}))
write_csv(figure_audit, "order32j_stopped_figure_endpoint_audit.csv")

all_id_nodes <- html_elements(doc, "[id]")
all_ids <- html_attr(all_id_nodes, "id")
all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]
id_counts <- table(all_ids)
duplicate_ids <- data.frame(
  id = names(id_counts[id_counts > 1L]),
  occurrences = as.integer(id_counts[id_counts > 1L]),
  stringsAsFactors = FALSE
)
write_csv(duplicate_ids, "order32j_stopped_duplicate_id_audit.csv")

header_rows <- lapply(table_endpoints, function(endpoint) {
  endpoint_id <- html_attr(endpoint, "id")
  table <- html_element(endpoint, "table.gt_table")
  nodes <- html_elements(table, "[headers]")
  if (!length(nodes)) {
    return(NULL)
  }
  do.call(rbind, lapply(nodes, function(node) {
    tokens <- strsplit(trimws(html_attr(node, "headers")), "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    do.call(rbind, lapply(tokens, function(token) {
      matches <- xml_find_all(table, sprintf(".//*[@id='%s']", token))
      data.frame(
        endpoint = endpoint_id,
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
write_csv(header_audit, "order32j_stopped_header_resolution_audit.csv")

idref_attributes <- c(
  "headers", "aria-labelledby", "aria-describedby", "for", "list",
  "aria-controls", "aria-owns", "aria-activedescendant"
)
idref_rows <- lapply(idref_attributes, function(attribute) {
  nodes <- html_elements(doc, sprintf("[%s]", attribute))
  if (!length(nodes)) {
    return(NULL)
  }
  do.call(rbind, lapply(nodes, function(node) {
    tokens <- strsplit(trimws(html_attr(node, attribute)), "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    do.call(rbind, lapply(tokens, function(token) {
      matches <- sum(all_ids == token)
      data.frame(
        attribute = attribute,
        token = token,
        matches_in_document = matches,
        pass = matches == 1L,
        stringsAsFactors = FALSE
      )
    }))
  }))
})
idref_audit <- do.call(rbind, Filter(Negate(is.null), idref_rows))
write_csv(idref_audit, "order32j_stopped_idref_resolution_audit.csv")

anchor_nodes <- html_elements(doc, "a[href]")
anchor_nodes <- anchor_nodes[outside_source_modal(anchor_nodes)]
hrefs <- html_attr(anchor_nodes, "href")
link_text <- vapply(anchor_nodes, clean_text, character(1))
doc_cache <- new.env(parent = emptyenv())
fragment_resolves_once <- function(target_path, fragment) {
  if (!nzchar(fragment)) {
    return(TRUE)
  }
  if (!file.exists(target_path)) {
    return(FALSE)
  }
  if (!grepl("\\.html?$", target_path, ignore.case = TRUE)) {
    return(TRUE)
  }
  key <- normalizePath(target_path, winslash = "/", mustWork = TRUE)
  if (!exists(key, envir = doc_cache, inherits = FALSE)) {
    assign(key, read_html(key), envir = doc_cache)
  }
  length(html_elements(get(key, envir = doc_cache), paste0("#", fragment))) == 1L
}
link_audit <- do.call(rbind, lapply(seq_along(hrefs), function(index) {
  href <- hrefs[[index]]
  external <- grepl("^(https?|mailto|tel):", href, ignore.case = TRUE)
  interactive <- identical(href, "javascript:void(0)")
  unsupported <- grepl("^[A-Za-z][A-Za-z0-9+.-]*:", href) &&
    !external && !grepl("^data:", href, ignore.case = TRUE) && !interactive
  forbidden <- !external && (
    grepl("\\.qmd($|[?#])", href, ignore.case = TRUE) ||
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
  if (interactive || external || grepl("^data:", href, ignore.case = TRUE)) {
    resolved_path <- ""
    target_exists <- TRUE
    fragment_ok <- TRUE
  } else if (unsupported) {
    resolved_path <- ""
    target_exists <- FALSE
    fragment_ok <- FALSE
  } else {
    resolved_path <- if (!nzchar(path_part)) {
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
    target_exists <- file.exists(resolved_path)
    fragment_ok <- target_exists &&
      fragment_resolves_once(resolved_path, fragment)
  }
  known_hold <- identical(link_text[[index]], "Supplementary information") &&
    identical(href, "../../../supplementary_information.html") && !target_exists
  data.frame(
    link_text = link_text[[index]],
    href = href,
    resolved_path = resolved_path,
    target_exists = target_exists,
    fragment = fragment,
    fragment_resolves_once = fragment_ok,
    forbidden = forbidden,
    known_hold = known_hold,
    pass = !forbidden && !unsupported &&
      ((target_exists && fragment_ok) || known_hold),
    stringsAsFactors = FALSE
  )
}))
write_csv(link_audit, "order32j_stopped_reader_link_audit.csv")

semantic_dir <- "/private/tmp/H01-order32i-semantics.Or8lWE"
semantic_summary <- read.csv(
  file.path(semantic_dir, "gt_html_semantic_post_render_summary.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
semantic_ledger <- read.csv(
  file.path(semantic_dir, semantic_summary$ledger_file[[1L]]),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
post_raw <- read_bytes(html_path)
reversed_raw <- apply_raw_replacements(post_raw, semantic_ledger, reverse = TRUE)
semantic_reverse <- data.frame(
  disposition = semantic_summary$disposition,
  table_count = semantic_summary$table_count,
  id_count = semantic_summary$id_count,
  headers_count = semantic_summary$headers_count,
  total_substitutions = semantic_summary$total_substitutions,
  expected_pre_sha256 = semantic_summary$pre_sha256,
  reversed_sha256 = sha256_raw(reversed_raw),
  expected_post_sha256 = semantic_summary$post_sha256,
  current_post_sha256 = artifact_sha256(html_path),
  pass = semantic_summary$disposition == "REPAIRED" &&
    semantic_summary$table_count == 20L &&
    semantic_summary$pre_sha256 == sha256_raw(reversed_raw) &&
    semantic_summary$post_sha256 == artifact_sha256(html_path),
  stringsAsFactors = FALSE
)
write_csv(semantic_reverse, "order32j_stopped_semantic_reverse_audit.csv")

site_registry <- read.csv(
  "config/site_display_registry.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE,
  fileEncoding = "UTF-8"
)
site_presence <- data.frame(
  display_name = site_registry$display_name,
  present = vapply(
    site_registry$display_name,
    function(label) grepl(label, main_text, fixed = TRUE),
    logical(1)
  ),
  stringsAsFactors = FALSE
)
write_csv(site_presence, "order32j_stopped_country_site_audit.csv")

source_links <- link_audit[
  grepl("H01_analysis_preparation_files/source-data/", link_audit$href),
  ,
  drop = FALSE
]
registration_links <- link_audit[
  grepl(
    "preregistration_deviations|h01-preregistration-deviations",
    link_audit$href
  ),
  ,
  drop = FALSE
]
result_link <- "../../../notebooks/hypotheses/H01.html"
result_anchor <- paste0(result_link, "#h01-preregistration-deviations")
result_doc <- read_html(result_html_relative)
result_main <- html_element(result_doc, "main#quarto-document-content")
companion_back <- "../../audit/hypotheses/H01/H01_analysis_preparation.html"
active_hrefs <- html_attr(html_elements(doc, ".sidebar-link.active[href]"), "href")

checks <- data.frame(
  check = c(
    "semantic_repair_reversible",
    "exact_20_native_gt_endpoints",
    "table_order_matches_source",
    "table_endpoints_complete",
    "exact_two_figure_endpoints",
    "figure_order_matches_source",
    "figure_endpoints_complete",
    "unique_document_ids",
    "headers_resolve_within_table",
    "all_idrefs_resolve_once",
    "no_error_warning_stderr_nodes",
    "no_unresolved_references",
    "all_reader_links_resolve",
    "no_forbidden_internal_links",
    "two_restored_download_links_resolve",
    "registration_links_resolve",
    "reciprocal_result_companion_links",
    "active_companion_navigation",
    "all_country_coded_sites_present",
    "build_qmd_matches_source",
    "one_top_to_bottom_mermaid"
  ),
  pass = c(
    semantic_reverse$pass,
    length(table_ids) == 20L && length(unique(table_ids)) == 20L,
    identical(table_ids, source_table_ids),
    nrow(table_audit) == 20L && all(table_audit$pass),
    length(figure_ids) == 2L && length(unique(figure_ids)) == 2L,
    identical(figure_ids, source_figure_ids),
    nrow(figure_audit) == 2L && all(figure_audit$pass),
    nrow(duplicate_ids) == 0L,
    nrow(header_audit) > 0L && all(header_audit$pass),
    nrow(idref_audit) > 0L && all(idref_audit$pass),
    length(html_elements(
      doc,
      ".cell-output-error, .cell-output-warning, .cell-output-stderr"
    )) == 0L,
    length(html_elements(doc, ".quarto-unresolved-ref, .quarto-unresolved-cite")) ==
      0L && !grepl("\\?@(fig|tbl|sec)-|\\(ref\\?\\)", main_text),
    nrow(link_audit) > 0L && all(link_audit$pass),
    !any(link_audit$forbidden),
    nrow(source_links) == 2L && all(source_links$pass),
    nrow(registration_links) >= 2L && all(registration_links$pass),
    any(link_audit$href == result_link & link_audit$pass) &&
      any(link_audit$href == result_anchor & link_audit$pass) &&
      length(html_elements(
        result_main,
        paste0("a[href='", companion_back, "']")
      )) >= 1L,
    length(active_hrefs) == 1L && identical(
      active_hrefs,
      "../../../audit/hypotheses/H01/H01_analysis_preparation.html"
    ),
    nrow(site_presence) == 9L && all(site_presence$present),
    identical(read_bytes(qmd_relative), read_bytes(build_qmd_relative)),
    length(html_elements(main, "pre.mermaid.mermaid-js")) == 1L &&
      grepl("flowchart TD", main_text, fixed = TRUE)
  ),
  stringsAsFactors = FALSE
)
checks$status <- ifelse(checks$pass, "PASS", "FAIL")
write_csv(checks, "order32j_stopped_html_contracts.csv")
cat(sprintf(
  paste0(
    "html_audit=%s contracts=%d/%d tables=%d figures=%d ",
    "headers=%d idrefs=%d links=%d downloads=%d\n"
  ),
  if (all(checks$pass)) "PASS" else "FAIL",
  sum(checks$pass),
  nrow(checks),
  length(table_ids),
  length(figure_ids),
  nrow(header_audit),
  nrow(idref_audit),
  nrow(link_audit),
  nrow(source_links)
))
if (any(!checks$pass)) {
  print(checks[!checks$pass, , drop = FALSE])
}
