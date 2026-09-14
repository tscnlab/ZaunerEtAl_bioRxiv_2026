#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
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
  "audit/hypotheses/H06_daily/report018_order48_result_render"
evidence_dir <- file.path(root, evidence_relative)
semantic_dir <- normalizePath(
  Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
  winslash = "/",
  mustWork = TRUE
)
html_relative <- "_build/nathealth/notebooks/hypotheses/H06_daily.html"
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
      )) >
        0L
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
  summary$table_count == 14L,
  summary$id_count == 113L,
  summary$headers_count == 705L,
  summary$total_substitutions == 818L
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

hash_text <- function(value) {
  digest::digest(enc2utf8(value), algo = "sha256", serialize = FALSE)
}

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

# The accepted normalization helper intentionally rewrites mutable gt
# attributes in its supplied DOM. Reparse the raw documents before auditing
# the final identifiers and references below.
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
  "tbl-h06-daily-analysis-roles",
  "tbl-h06-daily-fdr-families",
  "tbl-h06-daily-primary-matrix",
  "tbl-h06-daily-primary-site-interactions",
  "tbl-h06-daily-placement-work-free",
  "tbl-h06-daily-placement-activity",
  "tbl-h06-daily-placement-sleep",
  "tbl-h06-daily-gap-decision-changes",
  "tbl-h06-daily-joint-family-summary",
  "tbl-h06-daily-joint-stability-limitations",
  "tbl-h06-daily-joint-site-interactions",
  "tbl-h06-daily-temporal-gamm",
  "tbl-h06-daily-main-comparison",
  "tbl-h06-daily-diagnostic-summary"
)
expected_table_captions <- c(
  "Analysis roles and exact fitted-sample ranges.",
  "Twelve fixed 15-slot FDR families.",
  "Primary near-eye predictor-specific participant-day associations.",
  paste(
    "Site-average contrasts and site adjustment factors for primary",
    "interaction blocks retained by the global FDR rule."
  ),
  "Near-eye, chest, and paired/common estimates for Free versus Work day.",
  paste(
    "Near-eye, chest, and paired/common estimates for Active versus",
    "Sedentary status."
  ),
  paste(
    "Near-eye, chest, and paired/common estimates per additional hour of",
    "previous-night sleep."
  ),
  paste(
    "Primary versus gap-timing-unaware association decisions that crossed",
    "the FDR threshold."
  ),
  "Exploratory mutually adjusted daily-model FDR families.",
  "Covariate-adjustment shifts of at least one common-sample standard error.",
  paste(
    "Site-specific contrasts for conditionally supported exploratory",
    "interaction blocks."
  ),
  "Exploratory primary near-eye 30-minute GAMM summaries.",
  "Selected main hourly H06 versus daily mean-melEDI associations.",
  "Model-check and sensitivity classifications."
)

post_table_endpoints <- rvest::html_elements(
  post_main,
  '.quarto-float[id^="tbl-h06-daily-"]'
)
post_table_endpoints <- post_table_endpoints[
  outside_source_modal(post_table_endpoints)
]
pre_table_endpoints <- rvest::html_elements(
  pre_main,
  '.quarto-float[id^="tbl-h06-daily-"]'
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
  source_note <- clean_text(rvest::html_element(
    post_endpoint,
    ".gt_sourcenotes"
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
    source_note_count = length(rvest::html_elements(
      post_endpoint,
      ".gt_sourcenotes"
    )),
    caption = caption,
    expected_caption = expected_table_captions[[index]],
    caption_matches = grepl(
      expected_table_captions[[index]],
      caption,
      fixed = TRUE
    ),
    visible_text_sha256 = hash_text(clean_text(post_table)),
    source_note_sha256 = hash_text(source_note),
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
  nrow(table_audit) == 14L,
  all(table_audit$native_gt_count == 1L),
  all(table_audit$caption_count == 1L),
  all(table_audit$source_note_count == 1L),
  all(table_audit$caption_matches),
  all(table_audit$geometry_unchanged_across_hook),
  all(table_audit$visible_text_unchanged_across_hook)
)
write_evidence(table_audit, "table_endpoint_audit.csv")

expected_figures <- c(
  "fig-h06-daily-primary-ratio",
  "fig-h06-daily-primary-absolute",
  "fig-h06-daily-fdr-overview",
  "fig-h06-daily-primary-site-deviations",
  "fig-h06-daily-temporal-gamm"
)
figure_files <- c(
  "H06_daily_non_l10_production_primary_ratio_effects.png",
  "H06_daily_non_l10_production_primary_absolute_effects.png",
  "H06_daily_stage3_fdr_overview.png",
  "H06_daily_stage3_primary_site_deviations.png",
  "H06_daily_temporal_h02_primary_context_functions.png"
)
figure_hashes <- c(
  "a50f6b25c1c09abca1700870594d26a15e2085ec1c2a4c8eb5f6bc0f727cfa66",
  "da67b5f8a27b49d7c4d0e6426563d79aaa540ef835e350d02fd952a3a134c686",
  "48283afc83e9ebcd0f7d02177dacc162287940126c335b47efab11cc54c9edd9",
  "a1ddd2ae719d5a6ab11c1c591801d4b4aa7cb06f9eb0bcad7c983d8024fd86e1",
  "e28c639f23b3f33687ca046a77069153bb66073d29cd03d96fd03408c4317d98"
)
source_files <- c(
  "H06_daily_non_l10_production_primary_ratio_effects.csv",
  "H06_daily_non_l10_production_primary_absolute_effects.csv",
  "H06_daily_stage3_fdr_overview_figure.csv",
  "H06_daily_stage3_primary_site_deviation_figure.csv",
  "H06_daily_temporal_h02_primary_context_functions_figure_source.csv"
)
source_hashes <- c(
  "c7a1c0018e82db71e2fb0fe74d6e3e5a6645948017b10dd938fce18f6c5c2a9d",
  "2b695be686e6fdfdef9bdad4082be1fdcd1100e0d3d763fac35b4a75b8df11a7",
  "4a9a7c3f0877872e2efe7bfddd73afac1c50299f60474bd8d328ce945f17ddf1",
  "12193a0a1795fe478bf4829a3986c2b1290510038e4c4aed59aa7e61714bcbcc",
  "4c104c16734f5b23d02b864fdc90aee445538823e41fb0119e2de7ac9bd4ef63"
)

figure_endpoints <- rvest::html_elements(
  post_main,
  '.quarto-float[id^="fig-h06-daily-"]'
)
figure_endpoints <- figure_endpoints[outside_source_modal(figure_endpoints)]
figure_ids <- rvest::html_attr(figure_endpoints, "id")
all_main_links <- rvest::html_elements(post_main, "a[href]")
all_main_hrefs <- rvest::html_attr(all_main_links, "href")

figure_rows <- lapply(seq_along(figure_endpoints), function(index) {
  endpoint <- figure_endpoints[[index]]
  image <- rvest::html_element(endpoint, "img")
  figure_path <- file.path(
    root,
    "artifacts/10_figures/H06_daily",
    figure_files[[index]]
  )
  source_path <- file.path(
    root,
    "artifacts/11_source_data/H06_daily",
    source_files[[index]]
  )
  data.frame(
    order = index,
    endpoint = figure_ids[[index]],
    image_count = length(rvest::html_elements(endpoint, "img")),
    caption_count = length(rvest::html_elements(
      endpoint,
      "figcaption.quarto-float-caption"
    )),
    caption = clean_text(rvest::html_element(
      endpoint,
      "figcaption.quarto-float-caption"
    )),
    alt = rvest::html_attr(image, "alt"),
    embedded_png = startsWith(rvest::html_attr(image, "src"), "data:image/png"),
    durable_figure = file.path(
      "artifacts/10_figures/H06_daily",
      figure_files[[index]]
    ),
    durable_figure_sha256 = sha256_file(figure_path),
    expected_figure_sha256 = figure_hashes[[index]],
    paired_source = file.path(
      "artifacts/11_source_data/H06_daily",
      source_files[[index]]
    ),
    paired_source_sha256 = sha256_file(source_path),
    expected_source_sha256 = source_hashes[[index]],
    paired_source_link_count = sum(grepl(
      paste0(source_files[[index]], "$"),
      all_main_hrefs
    )),
    status = "PASS",
    stringsAsFactors = FALSE
  )
})
figure_audit <- do.call(rbind, figure_rows)
stopifnot(
  identical(figure_ids, expected_figures),
  nrow(figure_audit) == 5L,
  all(figure_audit$image_count == 1L),
  all(figure_audit$caption_count == 1L),
  all(nzchar(figure_audit$caption)),
  all(!is.na(figure_audit$alt) & nzchar(figure_audit$alt)),
  all(figure_audit$embedded_png),
  all(
    figure_audit$durable_figure_sha256 == figure_audit$expected_figure_sha256
  ),
  all(figure_audit$paired_source_sha256 == figure_audit$expected_source_sha256),
  all(figure_audit$paired_source_link_count >= 1L)
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
          data.frame(
            endpoint = endpoint_id,
            element = xml2::xml_name(node),
            header_token = token,
            matches_in_table = length(matches),
            resolves_to_th = length(matches) == 1L &&
              identical(xml2::xml_name(matches[[1L]]), "th"),
            status = ifelse(
              length(matches) == 1L &&
                identical(xml2::xml_name(matches[[1L]]), "th"),
              "PASS",
              "FAIL"
            ),
            stringsAsFactors = FALSE
          )
        })
      )
    })
  )
})
header_audit <- do.call(rbind, header_rows)
stopifnot(nrow(header_audit) == 1293L, all(header_audit$status == "PASS"))
write_evidence(header_audit, "table_header_reference_audit.csv")

idref_attributes <- c(
  "headers",
  "aria-labelledby",
  "aria-describedby",
  "for",
  "list",
  "aria-controls",
  "aria-owns",
  "aria-activedescendant"
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
    !external &&
    !data_uri
  forbidden <- !external &&
    !data_uri &&
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

dynamic_text <- c(
  "hourly H06 analysis",
  "analysis-preparation and provenance companion",
  "preregistration-deviations page",
  "main H06 report",
  "primary predictor scope",
  "model and site structure",
  "multiplicity and contrast decisions"
)
dynamic_href <- c(
  "../../notebooks/hypotheses/H06.html",
  "../../audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html",
  "../../notebooks/preregistration_deviations.html#dev-015",
  "../../notebooks/hypotheses/H06.html",
  "../../notebooks/preregistration_deviations.html#dev-030",
  "../../notebooks/preregistration_deviations.html#dev-031",
  "../../notebooks/preregistration_deviations.html#dev-032"
)
dynamic_rows <- lapply(seq_along(dynamic_text), function(index) {
  matches <- which(
    reader_link_audit$link_text == dynamic_text[[index]] &
      reader_link_audit$href == dynamic_href[[index]]
  )
  data.frame(
    order = index,
    link_text = dynamic_text[[index]],
    href = dynamic_href[[index]],
    matches = length(matches),
    target_exists = length(matches) == 1L &&
      reader_link_audit$target_exists[matches[[1L]]],
    fragment_resolves_once = length(matches) == 1L &&
      reader_link_audit$fragment_resolves_once[matches[[1L]]],
    status = ifelse(length(matches) == 1L, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
})
dynamic_link_audit <- do.call(rbind, dynamic_rows)
write_evidence(dynamic_link_audit, "dynamic_link_audit.csv")
stopifnot(
  nrow(dynamic_link_audit) == 7L,
  all(dynamic_link_audit$status == "PASS")
)

companion_path <- file.path(
  build_root,
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html"
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
    )
      return("")
    normalizePath(
      file.path(dirname(companion_path), URLdecode(path_part)),
      winslash = "/",
      mustWork = FALSE
    )
  },
  character(1)
)
reciprocal_matches <- which(
  companion_resolved ==
    normalizePath(
      html_path,
      winslash = "/",
      mustWork = TRUE
    )
)

active_nodes <- rvest::html_elements(post_document, "a.sidebar-link.active")
active_text <- vapply(active_nodes, clean_text, character(1))
active_href <- rvest::html_attr(active_nodes, "href")

site_names <- c(
  "Borås (SE)",
  "Delft (NL)",
  "Dortmund (DE)",
  "Tübingen (DE)",
  "Munich (DE)",
  "Madrid (ES)",
  "Izmir (TR)",
  "San José (CR)",
  "Kumasi (GH)"
)
main_text <- clean_text(post_main)
country_site_audit <- data.frame(
  site = site_names,
  present = vapply(site_names, grepl, logical(1), x = main_text, fixed = TRUE),
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(all(country_site_audit$present))
write_evidence(country_site_audit, "country_site_audit.csv")

embedded_defect_selectors <- c(
  ".cell-output-error",
  ".cell-output-warning",
  ".cell-output-stderr",
  ".quarto-error",
  ".quarto-warning",
  "pre.stderr"
)
embedded_defects <- vapply(
  embedded_defect_selectors,
  function(selector) {
    length(rvest::html_elements(post_main, selector))
  },
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
answer_callout <- rvest::html_elements(post_main, ".callout-note")
answer_title <- vapply(answer_callout, clean_text, character(1))
answer_matches <- sum(grepl("Answer in brief", answer_title, fixed = TRUE))
hierarchy_ok <- grepl("selected main H06 result", main_text, fixed = TRUE) &&
  grepl("complementary", main_text, ignore.case = TRUE)

search_text <- paste(
  readLines(
    file.path(build_root, "search.json"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
sitemap_text <- paste(
  readLines(
    file.path(build_root, "sitemap.xml"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)

reader_contract <- data.frame(
  check = c(
    "native gt tables",
    "figure endpoints",
    "dynamic QMD links",
    "source CSV links",
    "answer in brief note callout",
    "hourly-main complementary-daily hierarchy",
    "reciprocal companion link",
    "active navigation",
    "country-coded sites",
    "embedded error/warning/stderr nodes",
    "unresolved cross-reference text",
    "raw execution trace",
    "search integration",
    "sitemap integration"
  ),
  observed = c(
    nrow(table_audit),
    nrow(figure_audit),
    nrow(dynamic_link_audit),
    sum(grepl("[.]csv($|[?#])", reader_link_audit$href)),
    answer_matches,
    hierarchy_ok,
    length(reciprocal_matches),
    paste(active_text, collapse = "|"),
    sum(country_site_audit$present),
    sum(embedded_defects),
    unresolved_crossrefs,
    raw_trace,
    grepl("H06_daily.html", search_text, fixed = TRUE),
    grepl("notebooks/hypotheses/H06_daily.html", sitemap_text, fixed = TRUE)
  ),
  expected = c(
    14L,
    5L,
    7L,
    19L,
    1L,
    TRUE,
    1L,
    "H06 complementary daily results",
    9L,
    0L,
    FALSE,
    FALSE,
    TRUE,
    TRUE
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(all(
  as.character(reader_contract$observed) == reader_contract$expected
))
write_evidence(reader_contract, "reader_contract_audit.csv")

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

resource_rows <- build_delta$delta == "ADDED" &
  startsWith(build_delta$relative_path, "_build/nathealth/artifacts/")
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
  c(
    "_build/nathealth/search.json",
    "_build/nathealth/sitemap.xml"
  ) &
  build_delta$delta == "CHANGED_CONTENT"
build_delta$classification[site_rows] <- "EXPECTED_SITE_INTEGRATION"
css_row <- grepl(
  "^_build/nathealth/site_libs/bootstrap/bootstrap-.*[.]min[.]css$",
  build_delta$relative_path
) &
  build_delta$delta == "MTIME_ONLY"
build_delta$classification[css_row] <- "EXPECTED_BUILD_MTIME_ONLY"

build_delta$status <- ifelse(
  build_delta$classification != "UNCLASSIFIED" &
    (!resource_rows | build_delta$source_identical),
  "PASS",
  "FAIL"
)
stopifnot(
  nrow(build_pre) == 821L,
  nrow(build_post) == 846L,
  sum(build_delta$delta == "ADDED") == 25L,
  sum(build_delta$delta == "REMOVED") == 0L,
  sum(build_delta$delta == "CHANGED_CONTENT") == 3L,
  sum(build_delta$delta == "MTIME_ONLY") == 1L,
  sum(resource_rows) == 25L,
  all(build_delta$status == "PASS")
)
write_evidence(build_delta, "build_delta_postrender.csv")

build_classification <- data.frame(
  classification = sort(unique(build_delta$classification)),
  files = as.integer(table(build_delta$classification)[
    sort(unique(build_delta$classification))
  ]),
  status = "PASS",
  stringsAsFactors = FALSE
)
write_evidence(
  build_classification,
  "build_change_classification_postrender.csv"
)

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
  nrow(protected_pre) == 3260L,
  nrow(protected_post) == 3260L,
  sum(protected_merged$classification == "BYTE_IDENTICAL") == 3259L,
  sum(protected_merged$classification == "EXPECTED_RESULT_HTML_TRANSITION") ==
    1L,
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
  phase4$source == "notebooks/hypotheses/H06_daily.qmd",
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
  classification = "EXPECTED_HISTORICAL_TO_FRESH_TARGET_TRANSITION_PENDING_SHARED_INTEGRATION",
  manifest_byte_identical = sha256_file(phase4_path) ==
    "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334",
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(phase4_row) == 1L,
  phase4_transition$source_sha256 ==
    "01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08",
  phase4_transition$historical_html_sha256 ==
    "5a20c0680011be17111f72bb6b15aed6a4f4700c8866a13ea6dcf49a589fcce3",
  phase4_transition$fresh_html_sha256 == summary$post_sha256,
  phase4_transition$manifest_byte_identical
)
write_evidence(phase4_transition, "phase4_manifest_transition.csv")

qmd_text <- paste(
  readLines(
    file.path(root, "notebooks/hypotheses/H06_daily.qmd"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
historical_reconciliation <- data.frame(
  classification = c(
    "REPORT014_ACCEPTED_EDITORIAL_SOURCE_TRANSITION",
    "REPORT014_ACCEPTED_DISPLAY_ONLY_PNG_TRANSITION",
    "REPORT014_ACCEPTED_LINK_WORDING_TRANSITION"
  ),
  historical = c(
    "0318fd6cf874380631296d35095486b9de7f987a9779e4dc5d59c5a635a8c3dc",
    "69fd3786901993e9e9c0cfb3432abde07fbed14ccac03bea08ed9ea55751400c",
    "[main H06 analysis](H06.qmd)"
  ),
  accepted_current = c(
    "01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08",
    "a1ddd2ae719d5a6ab11c1c591801d4b4aa7cb06f9eb0bcad7c983d8024fd86e1",
    "[hourly H06 analysis](H06.qmd)"
  ),
  current_verified = c(
    sha256_file(file.path(root, "notebooks/hypotheses/H06_daily.qmd")) ==
      "01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08",
    sha256_file(file.path(
      root,
      "artifacts/10_figures/H06_daily/H06_daily_stage3_primary_site_deviations.png"
    )) ==
      "a1ddd2ae719d5a6ab11c1c591801d4b4aa7cb06f9eb0bcad7c983d8024fd86e1",
    grepl("[hourly H06 analysis](H06.qmd)", qmd_text, fixed = TRUE) &&
      !grepl("[main H06 analysis](H06.qmd)", qmd_text, fixed = TRUE)
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(historical_reconciliation) == 3L,
  all(historical_reconciliation$current_verified)
)
write_evidence(
  historical_reconciliation,
  "historical_classification_reconciliation.csv"
)

semantic_copy_paths <- c(
  file.path(evidence_dir, "gt_html_semantic_post_render_summary.csv"),
  file.path(
    evidence_dir,
    "001__build__nathealth__notebooks__hypotheses__H06_daily.html_gt_semantic_ledger.csv"
  )
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
    "figure endpoints and paired source data",
    "document IDs and table header references",
    "reader links and dynamic QMD links",
    "reader hierarchy, callout, navigation, and sites",
    "embedded execution defects",
    "build delta classification",
    "protected identity reconciliation",
    "historical REPORT-014 reconciliation",
    "phase-4 historical-to-fresh transition"
  ),
  status = "PASS",
  details = c(
    "REPAIRED; 818 substitutions; exact reverse and forward reapplication",
    "visible text, values, element order, captions, notes, links, and geometry unchanged",
    "14 native gt tables in accepted order",
    "five embedded PNG endpoints with durable figures and paired source CSVs",
    sprintf(
      paste(
        "%d unique document IDs; 1,293 tokens from 705 headers",
        "attributes resolve once to th"
      ),
      length(all_ids)
    ),
    sprintf(
      "%d main links pass; seven dynamic links pass",
      nrow(reader_link_audit)
    ),
    "Answer in brief, hierarchy, reciprocal companion link, active navigation, nine sites pass",
    "zero embedded error, warning, stderr, unresolved cross-reference, or raw trace",
    "25 source-identical resource copies, target HTML, search, sitemap, and one mtime-only CSS",
    "3,259 byte-identical protected paths plus the expected result HTML transition",
    "exactly three previously accepted REPORT-014 classifications",
    "shared corpus manifest unchanged; H06_daily HTML classified pending shared integration"
  ),
  stringsAsFactors = FALSE
)
write_evidence(nonvisual_status, "nonvisual_status.csv")

cat(sprintf(
  paste0(
    "ORDER48_NONVISUAL=PASS tables=%d figures=%d dynamic_links=%d ",
    "document_ids=%d headers=%d build_delta=%d protected=%d\n"
  ),
  nrow(table_audit),
  nrow(figure_audit),
  nrow(dynamic_link_audit),
  length(all_ids),
  nrow(header_audit),
  nrow(build_delta),
  nrow(protected_merged)
))
