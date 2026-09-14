#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(base64enc)
  library(digest)
  library(readr)
  library(rvest)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_relative <-
  "audit/hypotheses/H07/report018_order52_result_render"
evidence_dir <- file.path(root, evidence_relative)
semantic_dir <- normalizePath(
  Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
  winslash = "/",
  mustWork = TRUE
)
html_relative <- "_build/nathealth/notebooks/hypotheses/H07.html"
html_path <- file.path(root, html_relative)
build_root <- file.path(root, "_build/nathealth")

stopifnot(
  dir.exists(evidence_dir),
  dir.exists(semantic_dir),
  file.exists(html_path)
)

write_evidence <- function(object, name) {
  utils::write.csv(
    object,
    file.path(evidence_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

hash_text <- function(value) {
  digest::digest(enc2utf8(value), algo = "sha256", serialize = FALSE)
}

clean_text <- function(node) {
  value <- rvest::html_text2(node)
  value <- gsub("[[:space:]]+", " ", value)
  trimws(value)
}

outside_source_modal <- function(nodes) {
  if (!length(nodes)) return(logical())
  !vapply(
    nodes,
    function(node) {
      length(xml2::xml_find_all(
        node,
        "ancestor::*[@id='quarto-embedded-source-code-modal']"
      )) > 0L
    },
    logical(1)
  )
}

engine <- new.env(parent = globalenv())
sys.source(
  file.path(root, "scripts/report_harmonization/repair_gt_html_semantics.R"),
  envir = engine
)

summary_path <- file.path(
  semantic_dir,
  "gt_html_semantic_post_render_summary.csv"
)
summary <- readr::read_csv(summary_path, show_col_types = FALSE)
stopifnot(
  nrow(summary) == 1L,
  summary$target == html_relative,
  summary$disposition == "REPAIRED",
  summary$table_count == 11L,
  summary$total_substitutions == summary$id_count + summary$headers_count,
  summary$total_substitutions > 0L
)

ledger_path <- file.path(semantic_dir, summary$ledger_file)
ledger <- readr::read_csv(ledger_path, show_col_types = FALSE)
final_raw <- engine$read_file_raw(html_path)
reversed_raw <- engine$apply_raw_replacements(
  final_raw,
  ledger,
  reverse = TRUE
)
reapplied_raw <- engine$apply_raw_replacements(
  reversed_raw,
  ledger,
  reverse = FALSE
)

semantic_reverse <- data.frame(
  check = c(
    "summary post hash equals final HTML",
    "reverse hash equals pre-hook hash",
    "forward reapplication equals final HTML",
    "ledger row count equals summary substitutions",
    "ledger IDs equal summary ID count",
    "ledger headers equal summary headers count"
  ),
  observed = c(
    engine$sha256_raw(final_raw),
    engine$sha256_raw(reversed_raw),
    engine$sha256_raw(reapplied_raw),
    nrow(ledger),
    sum(ledger$attribute == "id"),
    sum(ledger$attribute == "headers")
  ),
  expected = c(
    summary$post_sha256,
    summary$pre_sha256,
    summary$post_sha256,
    summary$total_substitutions,
    summary$id_count,
    summary$headers_count
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(
  all(semantic_reverse$observed == semantic_reverse$expected),
  identical(final_raw, reapplied_raw)
)
write_evidence(semantic_reverse, "semantic_reverse_audit.csv")

pre_document <- xml2::read_html(rawToChar(reversed_raw))
post_document <- xml2::read_html(rawToChar(final_raw))
pre_main_nodes <- rvest::html_elements(
  pre_document,
  "main#quarto-document-content"
)
post_main_nodes <- rvest::html_elements(
  post_document,
  "main#quarto-document-content"
)
stopifnot(length(pre_main_nodes) == 1L, length(post_main_nodes) == 1L)
pre_main <- pre_main_nodes[[1L]]
post_main <- post_main_nodes[[1L]]

pre_elements <- xml2::xml_find_all(pre_document, "//*")
post_elements <- xml2::xml_find_all(post_document, "//*")
pre_links <- xml2::xml_attr(
  xml2::xml_find_all(pre_document, "//a[@href]"),
  "href"
)
post_links <- xml2::xml_attr(
  xml2::xml_find_all(post_document, "//a[@href]"),
  "href"
)
pre_captions <- vapply(
  rvest::html_elements(pre_main, "figcaption.quarto-float-caption"),
  clean_text,
  character(1)
)
post_captions <- vapply(
  rvest::html_elements(post_main, "figcaption.quarto-float-caption"),
  clean_text,
  character(1)
)
pre_notes <- vapply(
  rvest::html_elements(pre_main, ".gt_sourcenotes"),
  clean_text,
  character(1)
)
post_notes <- vapply(
  rvest::html_elements(post_main, ".gt_sourcenotes"),
  clean_text,
  character(1)
)

semantic_invariance <- data.frame(
  check = c(
    "normalized DOM excluding repaired gt attributes",
    "whole-document visible text",
    "main visible text and values",
    "element tag sequence",
    "link target sequence",
    "caption sequence",
    "source-note sequence"
  ),
  pre_value = c(
    hash_text(engine$normalized_dom_without_mutable_values(pre_document)),
    hash_text(xml2::xml_text(pre_document)),
    hash_text(xml2::xml_text(pre_main)),
    hash_text(paste(xml2::xml_name(pre_elements), collapse = "|")),
    hash_text(paste(pre_links, collapse = "|")),
    hash_text(paste(pre_captions, collapse = "|")),
    hash_text(paste(pre_notes, collapse = "|"))
  ),
  post_value = c(
    hash_text(engine$normalized_dom_without_mutable_values(post_document)),
    hash_text(xml2::xml_text(post_document)),
    hash_text(xml2::xml_text(post_main)),
    hash_text(paste(xml2::xml_name(post_elements), collapse = "|")),
    hash_text(paste(post_links, collapse = "|")),
    hash_text(paste(post_captions, collapse = "|")),
    hash_text(paste(post_notes, collapse = "|"))
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(all(semantic_invariance$pre_value == semantic_invariance$post_value))
write_evidence(semantic_invariance, "semantic_invariance_audit.csv")

# Reparse because the normalization helper mutates its supplied DOM.
pre_document <- xml2::read_html(rawToChar(reversed_raw))
post_document <- xml2::read_html(rawToChar(final_raw))
pre_main <- rvest::html_elements(
  pre_document,
  "main#quarto-document-content"
)[[1L]]
post_main <- rvest::html_elements(
  post_document,
  "main#quarto-document-content"
)[[1L]]

expected_tables <- c(
  "tbl-h07-response-specifications",
  "tbl-h07-near-samples",
  "tbl-h07-near-results",
  "tbl-h07-chest-samples",
  "tbl-h07-chest-results",
  "tbl-h07-diagnostic-summary",
  "tbl-h07-sensitivity-samples",
  "tbl-h07-sensitivity-classifications",
  "tbl-h07-model-form-sensitivities",
  "tbl-h07-near-loso",
  "tbl-h07-chest-loso"
)
expected_table_captions <- c(
  "Response specification for each planned personal light-exposure metric.",
  "Exact fitted near-eye sample for each personal light-exposure metric.",
  "Primary near-eye qualifying-transition classifications and derivative estimates at the longest recorded photoperiod.",
  "Exact fitted chest sample for each personal light-exposure metric.",
  "Complementary chest qualifying-transition classifications and derivative estimates at the longest recorded photoperiod.",
  "Summary of convergence, smooth-basis, temporal, overlap among nonlinear terms (concurvity), and residual model checks.",
  "Fitted sample sizes for the main data and metric-definition sensitivities. Ranges indicate metric-specific counts.",
  "Agreement of sensitivity qualifying-transition classifications with the reported pooled photoperiod analysis.",
  "Qualifying-transition stability under broader photoperiod smooths and fixed site effects.",
  "Leave-one-site-out influence on primary near-eye qualifying-transition classifications.",
  "Leave-one-site-out influence on complementary chest qualifying-transition classifications."
)

post_table_endpoints <- rvest::html_elements(
  post_main,
  '.quarto-float[id^="tbl-h07-"]'
)
post_table_endpoints <- post_table_endpoints[
  outside_source_modal(post_table_endpoints)
]
pre_table_endpoints <- rvest::html_elements(
  pre_main,
  '.quarto-float[id^="tbl-h07-"]'
)
pre_table_endpoints <- pre_table_endpoints[
  outside_source_modal(pre_table_endpoints)
]
post_table_ids <- rvest::html_attr(post_table_endpoints, "id")
pre_table_ids <- rvest::html_attr(pre_table_endpoints, "id")

table_rows <- lapply(seq_along(post_table_endpoints), function(index) {
  pre_endpoint <- pre_table_endpoints[[index]]
  post_endpoint <- post_table_endpoints[[index]]
  pre_table <- rvest::html_element(pre_endpoint, "table.gt_table")
  post_table <- rvest::html_element(post_endpoint, "table.gt_table")
  caption <- clean_text(rvest::html_element(
    post_endpoint,
    "figcaption.quarto-float-caption"
  ))
  counts <- function(table) {
    c(
      rows = length(rvest::html_elements(table, "tr")),
      header_rows = length(rvest::html_elements(table, "thead tr")),
      body_rows = length(rvest::html_elements(table, "tbody tr")),
      header_cells = length(rvest::html_elements(table, "th")),
      body_cells = length(rvest::html_elements(table, "td"))
    )
  }
  pre_counts <- counts(pre_table)
  post_counts <- counts(post_table)
  data.frame(
    order = index,
    endpoint = post_table_ids[[index]],
    native_gt_count = length(rvest::html_elements(
      post_endpoint,
      "table.gt_table"
    )),
    caption_count = length(rvest::html_elements(
      post_endpoint,
      "figcaption.quarto-float-caption"
    )),
    caption = caption,
    expected_caption = expected_table_captions[[index]],
    caption_matches = grepl(
      expected_table_captions[[index]],
      caption,
      fixed = TRUE
    ),
    visible_text_sha256 = hash_text(clean_text(post_table)),
    source_note_count = length(rvest::html_elements(
      post_endpoint,
      ".gt_sourcenotes"
    )),
    rows = post_counts[["rows"]],
    header_rows = post_counts[["header_rows"]],
    body_rows = post_counts[["body_rows"]],
    header_cells = post_counts[["header_cells"]],
    body_cells = post_counts[["body_cells"]],
    geometry_unchanged_across_hook = identical(pre_counts, post_counts),
    visible_text_unchanged_across_hook = identical(
      clean_text(pre_table),
      clean_text(post_table)
    ),
    status = "PASS",
    stringsAsFactors = FALSE
  )
})
table_audit <- do.call(rbind, table_rows)
stopifnot(
  identical(post_table_ids, expected_tables),
  identical(pre_table_ids, expected_tables),
  nrow(table_audit) == 11L,
  all(table_audit$native_gt_count == 1L),
  all(table_audit$caption_count == 1L),
  all(table_audit$caption_matches),
  all(table_audit$geometry_unchanged_across_hook),
  all(table_audit$visible_text_unchanged_across_hook)
)
write_evidence(table_audit, "table_endpoint_audit.csv")

expected_figures <- c(
  "fig-h07-near-smooth-derivative-pairs",
  "fig-h07-chest-smooth-derivative-pairs"
)
figure_files <- c(
  "H07_revised_smooth_derivative_pairs_near_eye.png",
  "H07_revised_smooth_derivative_pairs_chest.png"
)
figure_hashes <- c(
  "f19763fe3c14c723ac38846bf735c0465ba2ee18765777a4f7304c677be71113",
  "2a714e192bd5c266d03c6f74bdabae9424f5a3663940f0bc3ae5a9ae4e066cd5"
)
expected_figure_captions <- c(
  "Primary near-eye associations with civil photoperiod.",
  "Complementary chest associations with civil photoperiod."
)
figure_endpoints <- rvest::html_elements(
  post_main,
  '.quarto-float[id^="fig-h07-"]'
)
figure_endpoints <- figure_endpoints[outside_source_modal(figure_endpoints)]
figure_ids <- rvest::html_attr(figure_endpoints, "id")

figure_rows <- lapply(seq_along(figure_endpoints), function(index) {
  endpoint <- figure_endpoints[[index]]
  image <- rvest::html_element(endpoint, "img")
  image_src <- rvest::html_attr(image, "src")
  durable_path <- file.path(
    root,
    "artifacts/08_figures/H07",
    figure_files[[index]]
  )
  embedded <- startsWith(image_src, "data:image/png;base64,")
  embedded_sha <- if (embedded) {
    encoded <- sub("^data:image/png;base64,", "", image_src)
    digest::digest(
      base64enc::base64decode(encoded),
      algo = "sha256",
      serialize = FALSE
    )
  } else {
    ""
  }
  linked_path <- if (!embedded) {
    normalizePath(
      file.path(dirname(html_path), URLdecode(image_src)),
      winslash = "/",
      mustWork = FALSE
    )
  } else {
    ""
  }
  rendered_sha <- if (embedded) {
    embedded_sha
  } else if (file.exists(linked_path)) {
    sha256_file(linked_path)
  } else {
    ""
  }
  caption <- clean_text(rvest::html_element(
    endpoint,
    "figcaption.quarto-float-caption"
  ))
  data.frame(
    order = index,
    endpoint = figure_ids[[index]],
    image_count = length(rvest::html_elements(endpoint, "img")),
    caption_count = length(rvest::html_elements(
      endpoint,
      "figcaption.quarto-float-caption"
    )),
    caption = caption,
    expected_caption = expected_figure_captions[[index]],
    caption_matches = grepl(
      expected_figure_captions[[index]],
      caption,
      fixed = TRUE
    ),
    alt = rvest::html_attr(image, "alt"),
    embedded_png = embedded,
    representation = ifelse(embedded, "embedded_png", "linked_png"),
    rendered_sha256 = rendered_sha,
    durable_figure = file.path(
      "artifacts/08_figures/H07",
      figure_files[[index]]
    ),
    durable_sha256 = sha256_file(durable_path),
    expected_sha256 = figure_hashes[[index]],
    status = "PASS",
    stringsAsFactors = FALSE
  )
})
figure_audit <- do.call(rbind, figure_rows)
stopifnot(
  identical(figure_ids, expected_figures),
  nrow(figure_audit) == 2L,
  all(figure_audit$image_count == 1L),
  all(figure_audit$caption_count == 1L),
  all(figure_audit$caption_matches),
  all(!is.na(figure_audit$alt) & nchar(figure_audit$alt) >= 200L),
  all(figure_audit$durable_sha256 == figure_audit$expected_sha256),
  all(figure_audit$rendered_sha256 == figure_audit$expected_sha256)
)
write_evidence(figure_audit, "figure_endpoint_audit.csv")

all_id_nodes <- rvest::html_elements(post_document, "[id]")
all_ids <- rvest::html_attr(all_id_nodes, "id")
all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]
duplicate_ids <- unique(all_ids[duplicated(all_ids)])
duplicate_id_audit <- data.frame(
  document_ids = length(all_ids),
  unique_document_ids = length(unique(all_ids)),
  duplicate_ids = length(duplicate_ids),
  duplicate_values = paste(duplicate_ids, collapse = " | "),
  status = ifelse(length(duplicate_ids) == 0L, "PASS", "FAIL"),
  stringsAsFactors = FALSE
)
write_evidence(duplicate_id_audit, "duplicate_id_audit.csv")
stopifnot(length(duplicate_ids) == 0L)

header_rows <- lapply(post_table_endpoints, function(endpoint) {
  endpoint_id <- rvest::html_attr(endpoint, "id")
  table <- rvest::html_element(endpoint, "table.gt_table")
  nodes <- rvest::html_elements(table, "[headers]")
  do.call(
    rbind,
    lapply(nodes, function(node) {
      tokens <- strsplit(
        trimws(rvest::html_attr(node, "headers")),
        "[[:space:]]+"
      )[[1L]]
      do.call(
        rbind,
        lapply(tokens[nzchar(tokens)], function(token) {
          matches <- xml2::xml_find_all(table, sprintf(".//*[@id='%s']", token))
          resolves <- length(matches) == 1L &&
            identical(xml2::xml_name(matches[[1L]]), "th")
          data.frame(
            endpoint = endpoint_id,
            element = xml2::xml_name(node),
            header_token = token,
            matches_in_table = length(matches),
            resolves_to_th = resolves,
            status = ifelse(resolves, "PASS", "FAIL"),
            stringsAsFactors = FALSE
          )
        })
      )
    })
  )
})
header_audit <- do.call(rbind, header_rows)
stopifnot(nrow(header_audit) > 0L, all(header_audit$status == "PASS"))
write_evidence(header_audit, "table_header_reference_audit.csv")

idref_attributes <- c(
  "headers", "aria-labelledby", "aria-describedby", "for", "list",
  "aria-controls", "aria-owns", "aria-activedescendant"
)
idref_rows <- lapply(idref_attributes, function(attribute) {
  nodes <- rvest::html_elements(post_document, sprintf("[%s]", attribute))
  if (!length(nodes)) return(NULL)
  do.call(
    rbind,
    lapply(nodes, function(node) {
      tokens <- strsplit(
        trimws(rvest::html_attr(node, attribute)),
        "[[:space:]]+"
      )[[1L]]
      do.call(
        rbind,
        lapply(tokens[nzchar(tokens)], function(token) {
          matches <- sum(all_ids == token)
          data.frame(
            attribute = attribute,
            element = xml2::xml_name(node),
            token = token,
            matches_in_document = matches,
            status = ifelse(matches == 1L, "PASS", "FAIL"),
            stringsAsFactors = FALSE
          )
        })
      )
    })
  )
})
idref_audit <- do.call(rbind, Filter(Negate(is.null), idref_rows))
stopifnot(nrow(idref_audit) > 0L, all(idref_audit$status == "PASS"))
write_evidence(idref_audit, "document_idref_audit.csv")

document_cache <- new.env(parent = emptyenv())
fragment_resolves_once <- function(target_path, fragment) {
  if (!nzchar(fragment)) return(TRUE)
  if (!grepl("[.]html?$", target_path, ignore.case = TRUE)) return(TRUE)
  key <- normalizePath(target_path, winslash = "/", mustWork = TRUE)
  if (!exists(key, envir = document_cache, inherits = FALSE)) {
    assign(key, xml2::read_html(key), envir = document_cache)
  }
  target_document <- get(key, envir = document_cache, inherits = FALSE)
  target_ids <- rvest::html_attr(
    rvest::html_elements(target_document, "[id]"),
    "id"
  )
  sum(target_ids == fragment, na.rm = TRUE) == 1L
}

main_anchor_nodes <- rvest::html_elements(post_main, "a[href]")
main_anchor_nodes <- main_anchor_nodes[outside_source_modal(main_anchor_nodes)]
main_hrefs <- rvest::html_attr(main_anchor_nodes, "href")
main_link_text <- vapply(main_anchor_nodes, clean_text, character(1))

reader_link_rows <- lapply(seq_along(main_anchor_nodes), function(index) {
  href <- main_hrefs[[index]]
  external <- grepl("^(https?|mailto|tel):", href, ignore.case = TRUE)
  data_uri <- startsWith(href, "data:")
  unsupported <- grepl("^[A-Za-z][A-Za-z0-9+.-]*:", href) &&
    !external && !data_uri
  forbidden <- !external && !data_uri &&
    (grepl("[.]qmd($|[?#])", href, ignore.case = TRUE) ||
      grepl("file://", href, fixed = TRUE) ||
      grepl("_build", href, fixed = TRUE) ||
      grepl("/Users/", href, fixed = TRUE) ||
      grepl("^[A-Za-z]:[/\\\\]", href))
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
    order = index,
    link_text = main_link_text[[index]],
    href = href,
    kind = kind,
    resolved_path = resolved,
    target_exists = target_exists,
    fragment = fragment,
    fragment_resolves_once = fragment_ok,
    forbidden_internal_target = forbidden,
    status = ifelse(
      !forbidden && !unsupported && target_exists && fragment_ok,
      "PASS",
      "FAIL"
    ),
    stringsAsFactors = FALSE
  )
})
reader_link_audit <- do.call(rbind, reader_link_rows)
stopifnot(all(reader_link_audit$status == "PASS"))
write_evidence(reader_link_audit, "reader_link_audit.csv")

expected_reader_targets <- c(
  "../../notebooks/preparation/04_metric_derivation.html",
  "../../audit/hypotheses/H07/H07_analysis_preparation.html",
  "../../artifacts/09_tables/H07/H07_main_curve_points.csv",
  "../../artifacts/09_tables/H07/H07_revised_derivative_points.csv",
  "../../artifacts/09_tables/H07/H07_main_samples.csv",
  "../../artifacts/09_tables/H07/H07_revised_paired_figure_settings.csv",
  "../../notebooks/preregistration_deviations.html#dev-016",
  "../../notebooks/preregistration_deviations.html#dev-033",
  "../../notebooks/preregistration_deviations.html#dev-034"
)
dynamic_rows <- lapply(seq_along(expected_reader_targets), function(index) {
  target <- expected_reader_targets[[index]]
  matches <- which(reader_link_audit$href == target)
  data.frame(
    order = index,
    href = target,
    matches = length(matches),
    target_exists = length(matches) >= 1L &&
      all(reader_link_audit$target_exists[matches]),
    fragment_resolves_once = length(matches) >= 1L &&
      all(reader_link_audit$fragment_resolves_once[matches]),
    status = ifelse(length(matches) >= 1L, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
})
dynamic_link_audit <- do.call(rbind, dynamic_rows)
stopifnot(
  nrow(dynamic_link_audit) == 9L,
  all(dynamic_link_audit$status == "PASS"),
  all(dynamic_link_audit$target_exists),
  all(dynamic_link_audit$fragment_resolves_once)
)
write_evidence(dynamic_link_audit, "dynamic_link_audit.csv")

companion_path <- file.path(
  build_root,
  "audit/hypotheses/H07/H07_analysis_preparation.html"
)
companion_document <- xml2::read_html(companion_path)
companion_links <- rvest::html_elements(companion_document, "a[href]")
companion_hrefs <- rvest::html_attr(companion_links, "href")
companion_resolved <- vapply(
  companion_hrefs,
  function(href) {
    path_part <- sub("[?#].*$", "", href)
    if (
      !nzchar(path_part) ||
        grepl("^[A-Za-z][A-Za-z0-9+.-]*:", path_part) ||
        startsWith(path_part, "/")
    ) return("")
    normalizePath(
      file.path(dirname(companion_path), URLdecode(path_part)),
      winslash = "/",
      mustWork = FALSE
    )
  },
  character(1)
)
reciprocal_matches <- which(
  companion_resolved == normalizePath(html_path, winslash = "/", mustWork = TRUE)
)

active_nodes <- rvest::html_elements(post_document, "a.sidebar-link.active")
active_text <- vapply(active_nodes, clean_text, character(1))
active_href <- rvest::html_attr(active_nodes, "href")

site_names <- c(
  "Borås (SE)", "Delft (NL)", "Dortmund (DE)", "Tübingen (DE)",
  "Munich (DE)", "Madrid (ES)", "Izmir (TR)", "San José (CR)",
  "Kumasi (GH)"
)
main_text <- clean_text(post_main)
country_site_audit <- data.frame(
  site = site_names,
  present = vapply(site_names, grepl, logical(1), x = main_text, fixed = TRUE),
  status = "PASS",
  stringsAsFactors = FALSE
)
country_site_audit$status <- ifelse(
  country_site_audit$present,
  "PASS",
  "FAIL"
)
stopifnot(all(country_site_audit$present))
write_evidence(country_site_audit, "country_site_audit.csv")

embedded_defect_selectors <- c(
  ".cell-output-error", ".cell-output-warning", ".cell-output-stderr",
  ".quarto-error", ".quarto-warning", "pre.stderr"
)
embedded_defects <- vapply(
  embedded_defect_selectors,
  function(selector) length(rvest::html_elements(post_main, selector)),
  integer(1)
)
unresolved_crossrefs <- grepl(
  "[?]@(tbl|fig|sec|eq)-|@(tbl|fig|sec|eq)-[A-Za-z0-9_-]+",
  main_text,
  perl = TRUE
)
raw_trace <- any(vapply(
  c("processing file:", "output file:", "Quitting from lines", "pandoc --"),
  grepl,
  logical(1),
  x = main_text,
  fixed = TRUE
))
answer_nodes <- rvest::html_elements(post_main, ".callout-note")
answer_text <- vapply(answer_nodes, clean_text, character(1))
answer_matches <- sum(grepl("Answer in brief", answer_text, fixed = TRUE))

required_reader_phrases <- c(
  "six of nine primary near-eye metrics",
  "seven of nine metrics",
  "gap-timing-unaware dataset",
  "derivative-defined plateau pattern",
  "No physiological or environmental ceiling was identified",
  "not establish a ceiling",
  "do not identify a biological ceiling",
  "Absolute latitude cannot be separated from site"
)
reader_phrase_audit <- data.frame(
  phrase = required_reader_phrases,
  present = vapply(
    required_reader_phrases,
    grepl,
    logical(1),
    x = main_text,
    fixed = TRUE
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
reader_phrase_audit$status <- ifelse(
  reader_phrase_audit$present,
  "PASS",
  "FAIL"
)
stopifnot(all(reader_phrase_audit$present))
write_evidence(reader_phrase_audit, "reader_phrase_audit.csv")

search_text <- paste(
  readLines(file.path(build_root, "search.json"), warn = FALSE),
  collapse = "\n"
)
sitemap_text <- paste(
  readLines(file.path(build_root, "sitemap.xml"), warn = FALSE),
  collapse = "\n"
)

reader_contract <- data.frame(
  check = c(
    "native gt tables",
    "figure endpoints",
    "relative reader targets",
    "source CSV targets",
    "Answer in brief callout",
    "reciprocal companion target",
    "active H07 navigation",
    "country-coded sites",
    "embedded error warning or stderr nodes",
    "unresolved cross-reference text",
    "raw execution trace",
    "search integration",
    "sitemap integration"
  ),
  observed = c(
    nrow(table_audit),
    nrow(figure_audit),
    nrow(dynamic_link_audit),
    sum(grepl("[.]csv($|[?#])", dynamic_link_audit$href)),
    answer_matches,
    length(reciprocal_matches) >= 1L,
    length(active_nodes) == 1L && grepl("H07", active_text),
    sum(country_site_audit$present),
    sum(embedded_defects),
    unresolved_crossrefs,
    raw_trace,
    grepl("H07.html", search_text, fixed = TRUE),
    grepl("notebooks/hypotheses/H07.html", sitemap_text, fixed = TRUE)
  ),
  expected = c(
    11L, 2L, 9L, 4L, 1L, TRUE, TRUE, 9L, 0L, FALSE, FALSE, TRUE, TRUE
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(all(as.character(reader_contract$observed) == reader_contract$expected))
write_evidence(reader_contract, "reader_contract_audit.csv")

reader_test <- file.path(
  root,
  "tests/hypotheses/H07/test_h07_stage3_reader_report.R"
)
test_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", reader_test),
  stdout = TRUE,
  stderr = TRUE,
  env = sprintf("NATHEALTH_PROJECT_ROOT=%s", root)
)
test_status <- attr(test_output, "status")
test_pass <- identical(test_status, NULL) && any(grepl(
  "H07 Stage 3 reader-report checks passed",
  test_output,
  fixed = TRUE
))
reader_test_audit <- data.frame(
  test = "tests/hypotheses/H07/test_h07_stage3_reader_report.R",
  sha256 = sha256_file(reader_test),
  exit_status = if (is.null(test_status)) 0L else test_status,
  expected_message_present = test_pass,
  output = paste(test_output, collapse = " | "),
  status = ifelse(test_pass, "PASS", "FAIL"),
  stringsAsFactors = FALSE
)
write_evidence(reader_test_audit, "reader_test_audit.csv")
stopifnot(test_pass)

held_test <- file.path(
  root,
  "tests/hypotheses/H07/test_h07_preparation_report.R"
)
held_test_audit <- data.frame(
  test = "tests/hypotheses/H07/test_h07_preparation_report.R",
  sha256 = sha256_file(held_test),
  expected_sha256 =
    "89fd3eaa2f4f9928234280844e480ff5b863e104366af17675fe36366c456558",
  executed = FALSE,
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(held_test_audit$sha256 == held_test_audit$expected_sha256)
write_evidence(held_test_audit, "held_preparation_test_audit.csv")

read_inventory <- function(name) {
  readr::read_csv(file.path(evidence_dir, name), show_col_types = FALSE)
}

classify_inventory <- function(pre, post) {
  merged <- merge(
    pre,
    post,
    by = "relative_path",
    all = TRUE,
    suffixes = c("_pre", "_post")
  )
  merged$delta <- ifelse(
    is.na(merged$sha256_pre),
    "ADDED",
    ifelse(
      is.na(merged$sha256_post),
      "REMOVED",
      ifelse(
        merged$sha256_pre != merged$sha256_post,
        "CHANGED_CONTENT",
        ifelse(
          merged$modified_utc_pre != merged$modified_utc_post,
          "MTIME_ONLY",
          "UNCHANGED"
        )
      )
    )
  )
  merged
}

build_pre <- read_inventory("build_inventory_prerender.csv")
build_post <- read_inventory("build_inventory_postrender.csv")
build_merged <- classify_inventory(build_pre, build_post)
build_delta <- build_merged[
  build_merged$delta != "UNCHANGED",
  ,
  drop = FALSE
]
build_delta$classification <- "UNCLASSIFIED"
build_delta$source_relative_path <- ""
build_delta$source_identical <- NA

resource_rows <- startsWith(
  build_delta$relative_path,
  "_build/nathealth/artifacts/"
) & build_delta$delta %in% c("ADDED", "CHANGED_CONTENT", "MTIME_ONLY")
build_delta$classification[resource_rows] <-
  "TARGET_OWNED_SOURCE_IDENTICAL_RESOURCE_COPY"
build_delta$source_relative_path[resource_rows] <- sub(
  "^_build/nathealth/",
  "",
  build_delta$relative_path[resource_rows]
)
resource_source_paths <- file.path(
  root,
  build_delta$source_relative_path[resource_rows]
)
build_delta$source_identical[resource_rows] <-
  file.exists(resource_source_paths) &
  vapply(resource_source_paths, sha256_file, character(1)) ==
    build_delta$sha256_post[resource_rows]

target_row <- build_delta$relative_path == html_relative &
  build_delta$delta == "CHANGED_CONTENT"
build_delta$classification[target_row] <- "EXPECTED_RESULT_HTML_TRANSITION"

site_rows <- build_delta$relative_path %in%
  c("_build/nathealth/search.json", "_build/nathealth/sitemap.xml") &
  build_delta$delta == "CHANGED_CONTENT"
build_delta$classification[site_rows] <- "EXPECTED_SITE_INTEGRATION"

mtime_rows <- build_delta$delta == "MTIME_ONLY" &
  build_delta$classification == "UNCLASSIFIED"
build_delta$classification[mtime_rows] <- "BYTE_IDENTICAL_MTIME_ONLY"

build_delta$status <- ifelse(
  build_delta$classification != "UNCLASSIFIED" &
    (!resource_rows | build_delta$source_identical),
  "PASS",
  "FAIL"
)
stopifnot(
  sum(target_row) == 1L,
  !any(build_delta$delta == "REMOVED"),
  all(build_delta$status == "PASS")
)
write_evidence(build_delta, "build_delta_postrender.csv")

protected_pre <- read_inventory("protected_inventory_prerender.csv")
protected_post <- read_inventory("protected_inventory_postrender.csv")
protected_merged <- classify_inventory(protected_pre, protected_post)
protected_merged$classification <- ifelse(
  protected_merged$relative_path == html_relative &
    protected_merged$delta == "CHANGED_CONTENT",
  "EXPECTED_RESULT_HTML_TRANSITION",
  ifelse(
    protected_merged$delta == "UNCHANGED",
    "BYTE_IDENTICAL",
    "UNCLASSIFIED"
  )
)
protected_merged$status <- ifelse(
  protected_merged$classification == "UNCLASSIFIED",
  "FAIL",
  "PASS"
)
stopifnot(
  nrow(protected_pre) == nrow(protected_post),
  sum(
    protected_merged$classification == "EXPECTED_RESULT_HTML_TRANSITION"
  ) == 1L,
  all(protected_merged$status == "PASS")
)
write_evidence(
  protected_merged,
  "protected_reconciliation_postrender.csv"
)

phase4_path <- file.path(
  root,
  "audit/report_harmonization/phase4_corpus_manifest.csv"
)
phase4 <- readr::read_csv(phase4_path, show_col_types = FALSE)
phase4_row <- phase4[
  phase4$source == "notebooks/hypotheses/H07.qmd",
  ,
  drop = FALSE
]
phase4_transition <- data.frame(
  source = phase4_row$source,
  source_sha256 = phase4_row$source_sha256,
  expected_html = phase4_row$expected_html,
  historical_html_sha256 = phase4_row$html_sha256,
  fresh_html_sha256 = sha256_file(html_path),
  manifest_sha256 = sha256_file(phase4_path),
  classification =
    "EXPECTED_HISTORICAL_TO_FRESH_TARGET_TRANSITION_PENDING_SHARED_INTEGRATION",
  manifest_byte_identical = sha256_file(phase4_path) ==
    "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334",
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(phase4_row) == 1L,
  phase4_transition$source_sha256 ==
    "c779c57ffc64a15c82e519ef38e865a39108a6563d82e408e4522253c61e8226",
  phase4_transition$historical_html_sha256 ==
    "c45058b98da10a0e86d8fc6ed6183cabe7997fdb33414942874102faf953068d",
  phase4_transition$fresh_html_sha256 == summary$post_sha256,
  phase4_transition$manifest_byte_identical
)
write_evidence(phase4_transition, "phase4_manifest_transition.csv")

qa_path <- file.path(
  root,
  "artifacts/12_manifests/H07/H07_figure_readability_qa.csv"
)
qa <- readr::read_csv(qa_path, show_col_types = FALSE)
qa <- qa[qa$figure_id %in% expected_figures, , drop = FALSE]
final_size_audit <- data.frame(
  figure_id = qa$figure_id,
  figure_sha256 = qa$sha256,
  expected_sha256 = figure_hashes,
  intended_display_width_mm = qa$intended_display_width_mm,
  effective_final_essential_text_pt = qa$effective_final_essential_text_pt,
  minimum_required_pt = 7,
  historical_visual_status = qa$visual_status,
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(
  identical(final_size_audit$figure_id, expected_figures),
  all(final_size_audit$figure_sha256 == final_size_audit$expected_sha256),
  all(final_size_audit$intended_display_width_mm == 170),
  all(final_size_audit$effective_final_essential_text_pt >= 7),
  all(final_size_audit$historical_visual_status == "PASS")
)
write_evidence(final_size_audit, "figure_final_size_typography_audit.csv")

semantic_copy_paths <- c(
  file.path(evidence_dir, "gt_html_semantic_post_render_summary.csv"),
  file.path(evidence_dir, basename(ledger_path))
)
stopifnot(
  file.copy(summary_path, semantic_copy_paths[[1L]], overwrite = TRUE),
  file.copy(ledger_path, semantic_copy_paths[[2L]], overwrite = TRUE),
  sha256_file(summary_path) == sha256_file(semantic_copy_paths[[1L]]),
  sha256_file(ledger_path) == sha256_file(semantic_copy_paths[[2L]])
)

nonvisual_status <- data.frame(
  domain = c(
    "semantic disposition and exact reversal",
    "visible and structural invariance across semantic hook",
    "native gt endpoints",
    "figure endpoints and durable identity",
    "document IDs and table header references",
    "reader links and dynamic targets",
    "callout navigation reciprocal link and country-coded sites",
    "scientific classifications rule sensitivities and limitations",
    "embedded execution defects",
    "unchanged reader test",
    "held preparation test",
    "build delta classification",
    "protected identity reconciliation",
    "phase-4 historical-to-fresh transition",
    "170 mm figure typography contract"
  ),
  status = "PASS",
  details = c(
    sprintf(
      "REPAIRED with %d substitutions and exact reverse and forward proof",
      summary$total_substitutions
    ),
    "Visible text, values, order, captions, notes, links, and geometry unchanged",
    "11 native gt tables in accepted order",
    "Two rendered PNG figure resources equal the accepted durable hashes",
    sprintf(
      "%d unique document IDs and %d table header tokens resolve",
      length(all_ids),
      nrow(header_audit)
    ),
    sprintf(
      "%d main links pass and nine expected relative targets resolve",
      nrow(reader_link_audit)
    ),
    "Answer in brief, active H07 navigation, reciprocal companion target, and nine sites pass",
    "Six-of-nine near-eye, seven-of-nine chest, exact rule, sensitivities, and no-ceiling limits pass",
    "Zero embedded error, warning, stderr, unresolved cross-reference, or raw trace",
    "Current H07 reader test passed under R 4.6.1",
    "Held preparation test hash preserved and test not executed",
    sprintf("%d classified build deltas and no removals", nrow(build_delta)),
    sprintf(
      "%d protected paths, with only the expected result HTML transition",
      nrow(protected_merged)
    ),
    "Shared corpus manifest unchanged and historical H07 HTML transition classified",
    "Both accepted figures retain essential text above 7 pt at 170 mm"
  ),
  stringsAsFactors = FALSE
)
write_evidence(nonvisual_status, "nonvisual_status.csv")

cat(sprintf(
  paste0(
    "ORDER52_NONVISUAL=PASS tables=%d figures=%d links=%d ",
    "document_ids=%d header_tokens=%d build_delta=%d protected=%d\n"
  ),
  nrow(table_audit),
  nrow(figure_audit),
  nrow(dynamic_link_audit),
  length(all_ids),
  nrow(header_audit),
  nrow(build_delta),
  nrow(protected_merged)
))
