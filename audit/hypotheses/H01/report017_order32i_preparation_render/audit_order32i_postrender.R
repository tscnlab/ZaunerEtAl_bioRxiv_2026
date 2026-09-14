#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
semantic_dir <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)

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
source(file.path(
  root,
  "scripts/report_harmonization/repair_gt_html_semantics.R"
))

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H01/report017_order32i_preparation_render"
)
html_relative <-
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html"
html_path <- file.path(root, html_relative)
qmd_relative <- "audit/hypotheses/H01/H01_analysis_preparation.qmd"
qmd_path <- file.path(root, qmd_relative)
rendered_qmd_relative <-
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.qmd"
result_html_relative <- "_build/nathealth/notebooks/hypotheses/H01.html"
build_root <- file.path(root, "_build/nathealth")
stopifnot(file.exists(html_path), file.exists(qmd_path))

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
  value <- rvest::html_text2(node)
  value <- gsub("[[:space:]]+", " ", value)
  trimws(value)
}

read_bytes <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, what = "raw", n = as.numeric(file.info(path)$size))
}

outside_source_modal <- function(nodes) {
  if (!length(nodes)) return(logical())
  !vapply(nodes, function(node) {
    length(xml2::xml_find_all(
      node,
      "ancestor::*[@id='quarto-embedded-source-code-modal']"
    )) > 0L
  }, logical(1))
}

doc <- rvest::read_html(html_path)
main_nodes <- rvest::html_elements(doc, "main#quarto-document-content")
stopifnot(length(main_nodes) == 1L)
main <- main_nodes[[1L]]
main_text <- clean_text(main)

qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
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

table_endpoints <- rvest::html_elements(
  main,
  '.quarto-float[id^="tbl-h01-prep-"]'
)
table_endpoints <- table_endpoints[outside_source_modal(table_endpoints)]
table_ids <- rvest::html_attr(table_endpoints, "id")
table_audit <- do.call(rbind, lapply(seq_along(table_endpoints), function(i) {
  endpoint <- table_endpoints[[i]]
  tables <- rvest::html_elements(endpoint, "table.gt_table")
  captions <- rvest::html_elements(endpoint, "figcaption.quarto-float-caption")
  data.frame(
    endpoint_order = i,
    table_id = table_ids[[i]],
    native_gt_count = length(tables),
    caption_count = length(captions),
    caption = if (length(captions)) clean_text(captions[[1L]]) else "",
    thead_count = length(rvest::html_elements(endpoint, "table.gt_table thead")),
    th_count = length(rvest::html_elements(endpoint, "table.gt_table th")),
    tbody_count = length(rvest::html_elements(endpoint, "table.gt_table tbody")),
    body_row_count = length(rvest::html_elements(endpoint, "table.gt_table tbody tr")),
    body_cell_count = length(rvest::html_elements(endpoint, "table.gt_table tbody td")),
    pass = length(tables) == 1L &&
      length(captions) == 1L &&
      nzchar(if (length(captions)) clean_text(captions[[1L]]) else "") &&
      length(rvest::html_elements(endpoint, "table.gt_table thead")) == 1L &&
      length(rvest::html_elements(endpoint, "table.gt_table th")) > 0L &&
      length(rvest::html_elements(endpoint, "table.gt_table tbody")) == 1L &&
      length(rvest::html_elements(endpoint, "table.gt_table tbody tr")) > 0L &&
      length(rvest::html_elements(endpoint, "table.gt_table tbody td")) > 0L,
    stringsAsFactors = FALSE
  )
}))
write_csv(table_audit, "order32i_table_endpoint_audit.csv")

figure_endpoints <- rvest::html_elements(
  main,
  '.quarto-float[id^="fig-h01-prep-"]'
)
figure_endpoints <- figure_endpoints[outside_source_modal(figure_endpoints)]
figure_ids <- rvest::html_attr(figure_endpoints, "id")
figure_audit <- do.call(rbind, lapply(seq_along(figure_endpoints), function(i) {
  endpoint <- figure_endpoints[[i]]
  images <- rvest::html_elements(endpoint, "img")
  captions <- rvest::html_elements(endpoint, "figcaption.quarto-float-caption")
  image_src <- if (length(images)) rvest::html_attr(images[[1L]], "src") else ""
  image_alt <- if (length(images)) rvest::html_attr(images[[1L]], "alt") else ""
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
    endpoint_order = i,
    figure_id = figure_ids[[i]],
    image_count = length(images),
    caption_count = length(captions),
    caption = if (length(captions)) clean_text(captions[[1L]]) else "",
    image_src = image_src,
    image_alt = image_alt,
    resolved_path = resolved,
    source_exists = nzchar(resolved) && file.exists(resolved),
    pass = length(images) == 1L &&
      length(captions) == 1L &&
      nzchar(if (length(captions)) clean_text(captions[[1L]]) else "") &&
      !is.na(image_alt) && nzchar(image_alt) &&
      nzchar(resolved) && file.exists(resolved),
    stringsAsFactors = FALSE
  )
}))
write_csv(figure_audit, "order32i_figure_endpoint_audit.csv")

all_id_nodes <- rvest::html_elements(doc, "[id]")
all_ids <- rvest::html_attr(all_id_nodes, "id")
all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]
id_counts <- table(all_ids)
duplicate_id_audit <- data.frame(
  id = names(id_counts[id_counts > 1L]),
  occurrences = as.integer(id_counts[id_counts > 1L]),
  stringsAsFactors = FALSE
)
write_csv(duplicate_id_audit, "order32i_duplicate_id_audit.csv")

header_rows <- lapply(table_endpoints, function(endpoint) {
  endpoint_id <- rvest::html_attr(endpoint, "id")
  table <- rvest::html_element(endpoint, "table.gt_table")
  nodes <- rvest::html_elements(table, "[headers]")
  if (!length(nodes)) return(NULL)
  do.call(rbind, lapply(nodes, function(node) {
    tokens <- strsplit(trimws(rvest::html_attr(node, "headers")), "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    do.call(rbind, lapply(tokens, function(token) {
      matches <- xml2::xml_find_all(table, sprintf(".//*[@id='%s']", token))
      data.frame(
        endpoint = endpoint_id,
        element = xml2::xml_name(node),
        header_token = token,
        matches_in_table = length(matches),
        resolves_to_th = length(matches) == 1L &&
          identical(xml2::xml_name(matches[[1L]]), "th"),
        pass = length(matches) == 1L &&
          identical(xml2::xml_name(matches[[1L]]), "th"),
        stringsAsFactors = FALSE
      )
    }))
  }))
})
header_audit <- do.call(rbind, Filter(Negate(is.null), header_rows))
write_csv(header_audit, "order32i_header_resolution_audit.csv")

idref_attributes <- c(
  "headers", "aria-labelledby", "aria-describedby", "for", "list",
  "aria-controls", "aria-owns", "aria-activedescendant"
)
idref_rows <- lapply(idref_attributes, function(attribute) {
  nodes <- rvest::html_elements(doc, sprintf("[%s]", attribute))
  if (!length(nodes)) return(NULL)
  do.call(rbind, lapply(nodes, function(node) {
    tokens <- strsplit(
      trimws(rvest::html_attr(node, attribute)),
      "[[:space:]]+"
    )[[1L]]
    tokens <- tokens[nzchar(tokens)]
    do.call(rbind, lapply(tokens, function(token) {
      matches <- sum(all_ids == token)
      data.frame(
        attribute = attribute,
        element = xml2::xml_name(node),
        token = token,
        matches_in_document = matches,
        pass = matches == 1L,
        stringsAsFactors = FALSE
      )
    }))
  }))
})
idref_audit <- do.call(rbind, Filter(Negate(is.null), idref_rows))
write_csv(idref_audit, "order32i_idref_resolution_audit.csv")

anchor_nodes <- rvest::html_elements(doc, "a[href]")
anchor_nodes <- anchor_nodes[outside_source_modal(anchor_nodes)]
hrefs <- rvest::html_attr(anchor_nodes, "href")
link_text <- vapply(anchor_nodes, clean_text, character(1))
doc_cache <- new.env(parent = emptyenv())

fragment_resolves_once <- function(target_path, fragment) {
  if (!nzchar(fragment)) return(TRUE)
  if (!file.exists(target_path)) return(FALSE)
  if (!grepl("\\.html?$", target_path, ignore.case = TRUE)) return(TRUE)
  key <- normalizePath(target_path, winslash = "/", mustWork = TRUE)
  if (!exists(key, envir = doc_cache, inherits = FALSE)) {
    assign(key, rvest::read_html(key), envir = doc_cache)
  }
  target_doc <- get(key, envir = doc_cache, inherits = FALSE)
  length(rvest::html_elements(target_doc, paste0("#", fragment))) == 1L
}

link_audit <- do.call(rbind, lapply(seq_along(hrefs), function(i) {
  href <- hrefs[[i]]
  external <- grepl("^(https?|mailto|tel):", href, ignore.case = TRUE)
  interactive_control <- identical(href, "javascript:void(0)")
  unsupported_scheme <- grepl("^[A-Za-z][A-Za-z0-9+.-]*:", href) &&
    !external && !grepl("^data:", href, ignore.case = TRUE)
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
  if (interactive_control) {
    resolved_path <- ""
    target_exists <- TRUE
    fragment_ok <- TRUE
    kind <- "interactive_control"
  } else if (external || grepl("^data:", href, ignore.case = TRUE)) {
    resolved_path <- ""
    target_exists <- TRUE
    fragment_ok <- TRUE
    kind <- "external"
  } else if (unsupported_scheme) {
    resolved_path <- ""
    target_exists <- FALSE
    fragment_ok <- FALSE
    kind <- "unsupported_scheme"
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
    kind <- "local"
  }
  known_doc001_hold <- identical(link_text[[i]], "Supplementary information") &&
    identical(href, "../../../supplementary_information.html") &&
    !target_exists
  data.frame(
    link_text = link_text[[i]],
    href = href,
    kind = kind,
    resolved_path = resolved_path,
    target_exists = target_exists,
    fragment = fragment,
    fragment_resolves_once = fragment_ok,
    forbidden_internal_target = forbidden,
    interactive_control = interactive_control,
    known_doc001_hold = known_doc001_hold,
    pass = !forbidden &&
      (!unsupported_scheme || interactive_control) &&
      (target_exists && fragment_ok || known_doc001_hold),
    stringsAsFactors = FALSE
  )
}))
write_csv(link_audit, "order32i_reader_link_audit.csv")

semantic_summary_path <- file.path(
  semantic_dir,
  "gt_html_semantic_post_render_summary.csv"
)
semantic_summary <- utils::read.csv(
  semantic_summary_path,
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
post_raw <- read_bytes(html_path)
reversed_raw <- apply_raw_replacements(post_raw, semantic_ledger, reverse = TRUE)
reverse_path <- file.path(evidence_dir, "order32i_semantic_reverse_audit.csv")
reverse_audit <- data.frame(
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
  pass = semantic_summary$disposition == "REPAIRED" &&
    semantic_summary$table_count == 20L &&
    semantic_summary$id_count == 169L &&
    semantic_summary$headers_count == 797L &&
    semantic_summary$total_substitutions == nrow(semantic_ledger) &&
    semantic_summary$pre_sha256 == sha256_raw(reversed_raw) &&
    semantic_summary$pre_bytes == length(reversed_raw) &&
    semantic_summary$post_sha256 == artifact_sha256(html_path) &&
    semantic_summary$post_bytes == as.numeric(file.info(html_path)$size),
  stringsAsFactors = FALSE
)
write_csv(reverse_audit, basename(reverse_path))

manifest_path <-
  "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv"
manifest <- utils::read.csv(
  manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
manifest_absolute <- file.path(root, manifest$path)
manifest_exists <- file.exists(manifest_absolute) & !dir.exists(manifest_absolute)
manifest_current_sha <- rep(NA_character_, nrow(manifest))
manifest_current_sha[manifest_exists] <- vapply(
  manifest_absolute[manifest_exists],
  artifact_sha256,
  character(1)
)
manifest_current_bytes <- rep(NA_real_, nrow(manifest))
manifest_current_bytes[manifest_exists] <- as.numeric(
  file.info(manifest_absolute[manifest_exists])$size
)
manifest_audit <- data.frame(
  path = manifest$path,
  expected_sha256 = manifest$sha256,
  current_sha256 = manifest_current_sha,
  expected_bytes = manifest$bytes,
  current_bytes = manifest_current_bytes,
  exists = manifest_exists,
  status = ifelse(
    !manifest_exists,
    "MISSING",
    ifelse(
      manifest$sha256 == manifest_current_sha &
        as.numeric(manifest$bytes) == manifest_current_bytes,
      "PASS",
      "HASH_OR_SIZE_MISMATCH"
    )
  ),
  stringsAsFactors = FALSE
)
write_csv(manifest_audit, "order32i_preparation_manifest_audit.csv")

pre_build <- utils::read.csv(
  file.path(evidence_dir, "order32i_build_inventory_pre.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
post_build <- utils::read.csv(
  file.path(evidence_dir, "order32i_build_inventory_post.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
build_delta <- merge(
  pre_build,
  post_build,
  by = "path",
  all = TRUE,
  suffixes = c("_pre", "_post")
)
same_content <- !is.na(build_delta$type_pre) &
  !is.na(build_delta$type_post) &
  build_delta$type_pre == build_delta$type_post &
  (
    build_delta$type_pre != "file" |
      build_delta$sha256_pre == build_delta$sha256_post &
        build_delta$bytes_pre == build_delta$bytes_post
  )
build_delta$change <- ifelse(
  is.na(build_delta$type_pre),
  "CREATED",
  ifelse(
    is.na(build_delta$type_post),
    "DELETED",
    ifelse(
      same_content & build_delta$mtime_utc_pre == build_delta$mtime_utc_post,
      "UNCHANGED",
      ifelse(same_content, "MTIME_ONLY", "CONTENT_CHANGED")
    )
  )
)
target_prefix <-
  "audit/hypotheses/H01/H01_analysis_preparation_files/"
allowed_content_paths <- c(
  "audit/hypotheses/H01/H01_analysis_preparation.html",
  "search.json",
  "sitemap.xml"
)
source_data_paths <- c(
  paste0(target_prefix, "source-data"),
  paste0(
    target_prefix,
    "source-data/H01_preparation_fitted_sample_support.csv"
  ),
  paste0(
    target_prefix,
    "source-data/H01_preparation_model_frame_retention.csv"
  )
)
build_delta$classification <- ifelse(
  build_delta$change %in% c("UNCHANGED", "MTIME_ONLY"),
  "ALLOWED_NO_CONTENT_CHANGE",
  ifelse(
    build_delta$path %in% allowed_content_paths &
      build_delta$change == "CONTENT_CHANGED",
    "ALLOWED_RENDER_OUTPUT",
    ifelse(
      build_delta$path %in% source_data_paths & build_delta$change == "DELETED",
      "DEFECT_SOURCE_DATA_REMOVED",
      "UNCLASSIFIED_CHANGE"
    )
  )
)
write_csv(build_delta, "order32i_build_delta.csv")

pre_protected <- utils::read.csv(
  file.path(evidence_dir, "order32i_protected_inventory_pre.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
post_protected <- utils::read.csv(
  file.path(evidence_dir, "order32i_protected_inventory_post.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
protected_reconciliation <- merge(
  pre_protected,
  post_protected,
  by = "path",
  all = TRUE,
  suffixes = c("_pre", "_post")
)
protected_reconciliation$content_identical <-
  protected_reconciliation$sha256_pre == protected_reconciliation$sha256_post &
  protected_reconciliation$bytes_pre == protected_reconciliation$bytes_post
protected_reconciliation$classification <- ifelse(
  protected_reconciliation$content_identical,
  "PASS_IDENTICAL",
  ifelse(
    protected_reconciliation$path == html_relative,
    "EXPECTED_TARGET_HTML_CHANGE",
    "FAIL_PROTECTED_DRIFT"
  )
)
write_csv(
  protected_reconciliation,
  "order32i_protected_reconciliation.csv"
)

site_registry <- utils::read.csv(
  "config/site_display_registry.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE,
  fileEncoding = "UTF-8"
)
site_presence <- data.frame(
  display_order = site_registry$display_order,
  display_name = site_registry$display_name,
  present = vapply(
    site_registry$display_name,
    function(label) grepl(label, main_text, fixed = TRUE),
    logical(1)
  ),
  stringsAsFactors = FALSE
)
write_csv(site_presence, "order32i_country_site_label_audit.csv")

source_links <- link_audit[
  grepl("H01_analysis_preparation_files/source-data/", link_audit$href),
  ,
  drop = FALSE
]
registration_links <- link_audit[
  grepl("preregistration_deviations|h01-preregistration-deviations", link_audit$href),
  ,
  drop = FALSE
]
active_hrefs <- rvest::html_attr(
  rvest::html_elements(doc, ".sidebar-link.active[href]"),
  "href"
)
result_link <- "../../../notebooks/hypotheses/H01.html"
result_anchor_link <- paste0(result_link, "#h01-preregistration-deviations")
result_doc <- rvest::read_html(file.path(root, result_html_relative))
result_main <- rvest::html_element(result_doc, "main#quarto-document-content")
companion_back_href <-
  "../../audit/hypotheses/H01/H01_analysis_preparation.html"
mermaid_count <- length(rvest::html_elements(main, "pre.mermaid.mermaid-js"))

rendered_source_identical <- file.exists(rendered_qmd_relative) &&
  identical(read_bytes(qmd_path), read_bytes(rendered_qmd_relative))
checks <- data.frame(
  check = c(
    "semantic_hook_repaired_and_reversible",
    "exact_20_native_gt_endpoints",
    "table_endpoint_order_matches_source",
    "all_table_endpoints_complete",
    "exact_two_figure_endpoints",
    "figure_endpoint_order_matches_source",
    "all_figure_endpoints_complete",
    "one_top_to_bottom_mermaid_source",
    "unique_document_ids",
    "all_headers_resolve_once_within_table",
    "all_explicit_idrefs_resolve_once",
    "no_cell_output_errors_or_warnings",
    "no_unresolved_cross_references",
    "all_reader_links_resolve",
    "no_forbidden_internal_reader_links",
    "both_source_data_links_present_and_resolve",
    "registration_links_and_anchors_resolve",
    "reciprocal_result_and_companion_links",
    "active_companion_navigation",
    "all_nine_country_coded_site_names_present",
    "rendered_qmd_copy_matches_source",
    "preparation_manifest_all_rows_exact",
    "protected_inventory_unchanged_except_target_html",
    "build_delta_fully_classified_without_defect"
  ),
  pass = c(
    isTRUE(reverse_audit$pass),
    length(table_ids) == 20L && length(unique(table_ids)) == 20L,
    identical(table_ids, source_table_ids),
    nrow(table_audit) == 20L && all(table_audit$pass),
    length(figure_ids) == 2L && length(unique(figure_ids)) == 2L,
    identical(figure_ids, source_figure_ids),
    nrow(figure_audit) == 2L && all(figure_audit$pass),
    mermaid_count == 1L && grepl("flowchart TD", main_text, fixed = TRUE),
    nrow(duplicate_id_audit) == 0L,
    nrow(header_audit) > 0L && all(header_audit$pass),
    nrow(idref_audit) > 0L && all(idref_audit$pass),
    length(rvest::html_elements(
      doc,
      ".cell-output-error, .cell-output-warning"
    )) == 0L,
    length(rvest::html_elements(
      doc,
      ".quarto-unresolved-ref, .quarto-unresolved-cite"
    )) == 0L &&
      !grepl("\\?@(fig|tbl|sec)-|\\(ref\\?\\)", main_text),
    nrow(link_audit) > 0L && all(link_audit$pass),
    !any(link_audit$forbidden_internal_target),
    nrow(source_links) == 2L && all(source_links$pass),
    nrow(registration_links) >= 2L && all(registration_links$pass),
    any(link_audit$href == result_link & link_audit$pass) &&
      any(link_audit$href == result_anchor_link & link_audit$pass) &&
      length(rvest::html_elements(
        result_main,
        paste0("a[href='", companion_back_href, "']")
      )) >= 1L,
    length(active_hrefs) == 1L &&
      identical(
        active_hrefs,
        "../../../audit/hypotheses/H01/H01_analysis_preparation.html"
      ),
    nrow(site_presence) == 9L && all(site_presence$present),
    rendered_source_identical,
    all(manifest_audit$status == "PASS"),
    all(protected_reconciliation$classification %in% c(
      "PASS_IDENTICAL",
      "EXPECTED_TARGET_HTML_CHANGE"
    )) &&
      sum(
        protected_reconciliation$classification ==
          "EXPECTED_TARGET_HTML_CHANGE"
      ) == 1L,
    !any(build_delta$classification %in% c(
      "DEFECT_SOURCE_DATA_REMOVED",
      "UNCLASSIFIED_CHANGE"
    ))
  ),
  evidence = c(
    sprintf(
      "%s; %d tables, %d IDs, %d headers, %d substitutions",
      semantic_summary$disposition,
      semantic_summary$table_count,
      semantic_summary$id_count,
      semantic_summary$headers_count,
      semantic_summary$total_substitutions
    ),
    sprintf("%d endpoints; %d unique", length(table_ids), length(unique(table_ids))),
    sprintf("source=%d rendered=%d", length(source_table_ids), length(table_ids)),
    sprintf("%d/%d complete", sum(table_audit$pass), nrow(table_audit)),
    sprintf("%d endpoints; %d unique", length(figure_ids), length(unique(figure_ids))),
    sprintf("source=%d rendered=%d", length(source_figure_ids), length(figure_ids)),
    sprintf("%d/%d complete", sum(figure_audit$pass), nrow(figure_audit)),
    sprintf("mermaid_count=%d", mermaid_count),
    sprintf("duplicate_ids=%d", nrow(duplicate_id_audit)),
    sprintf("header_tokens=%d failures=%d", nrow(header_audit), sum(!header_audit$pass)),
    sprintf("idrefs=%d failures=%d", nrow(idref_audit), sum(!idref_audit$pass)),
    sprintf(
      "errors=%d warnings=%d",
      length(rvest::html_elements(doc, ".cell-output-error")),
      length(rvest::html_elements(doc, ".cell-output-warning"))
    ),
    "no unresolved-reference elements or tokens",
    sprintf("links=%d failures=%d", nrow(link_audit), sum(!link_audit$pass)),
    sprintf("forbidden=%d", sum(link_audit$forbidden_internal_target)),
    sprintf("source_links=%d resolving=%d", nrow(source_links), sum(source_links$pass)),
    sprintf("registration_links=%d resolving=%d", nrow(registration_links), sum(registration_links$pass)),
    "result link, result registration anchor, and result-to-companion link",
    paste(active_hrefs, collapse = "; "),
    sprintf("site_labels=%d/%d", sum(site_presence$present), nrow(site_presence)),
    sprintf(
      "source=%s rendered_copy=%s",
      artifact_sha256(qmd_path),
      if (file.exists(rendered_qmd_relative)) {
        artifact_sha256(rendered_qmd_relative)
      } else {
        "MISSING"
      }
    ),
    sprintf(
      "manifest_rows=%d pass=%d missing=%d mismatch=%d",
      nrow(manifest_audit),
      sum(manifest_audit$status == "PASS"),
      sum(manifest_audit$status == "MISSING"),
      sum(manifest_audit$status == "HASH_OR_SIZE_MISMATCH")
    ),
    paste(
      names(table(protected_reconciliation$classification)),
      as.integer(table(protected_reconciliation$classification)),
      collapse = "; "
    ),
    paste(
      names(table(build_delta$classification)),
      as.integer(table(build_delta$classification)),
      collapse = "; "
    )
  ),
  stringsAsFactors = FALSE
)
checks$status <- ifelse(checks$pass, "PASS", "FAIL")
write_csv(checks, "order32i_postrender_contracts.csv")

cat(sprintf(
  paste0(
    "contracts=%d pass=%d fail=%d tables=%d figures=%d links=%d ",
    "manifest_missing=%d manifest_mismatch=%d build_defects=%d\n"
  ),
  nrow(checks),
  sum(checks$status == "PASS"),
  sum(checks$status == "FAIL"),
  length(table_ids),
  length(figure_ids),
  nrow(link_audit),
  sum(manifest_audit$status == "MISSING"),
  sum(manifest_audit$status == "HASH_OR_SIZE_MISMATCH"),
  sum(build_delta$classification %in% c(
    "DEFECT_SOURCE_DATA_REMOVED",
    "UNCLASSIFIED_CHANGE"
  ))
))
print(checks[checks$status == "FAIL", c("check", "evidence"), drop = FALSE])
