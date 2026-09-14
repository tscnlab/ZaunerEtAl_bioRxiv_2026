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
  "audit/hypotheses/H02/report017_order33g_result_completion"
)
prior_evidence <- file.path(
  root,
  "audit/hypotheses/H02/report017_order33f_result_render"
)
html_path <- file.path(root, "_build/nathealth/notebooks/hypotheses/H02.html")
build_root <- file.path(root, "_build/nathealth")
semantic_dir <- normalizePath(
  "/private/tmp/H02-order33f-semantics.Cux4Wg",
  winslash = "/",
  mustWork = TRUE
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

read_prior <- function(filename) {
  utils::read.csv(
    file.path(prior_evidence, filename),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

expected_html_sha <-
  "736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9"
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

stopifnot(
  artifact_sha256(html_path) == expected_html_sha,
  as.numeric(file.info(html_path)$size) == 296427
)

document <- read_html(html_path)
main <- html_elements(document, "main#quarto-document-content")
stopifnot(length(main) == 1L)
main <- main[[1L]]

table_ids <- html_attr(
  html_elements(main, '.quarto-float[id^="tbl-h02-"]'),
  "id"
)
figure_ids <- html_attr(
  html_elements(main, '.quarto-float[id^="fig-h02-"]'),
  "id"
)
table_caption_counts <- vapply(expected_tables, function(id) {
  endpoint <- html_element(main, paste0("#", id))
  length(html_elements(endpoint, "figcaption.quarto-float-caption"))
}, integer(1))
figure_caption_counts <- vapply(expected_figures, function(id) {
  endpoint <- html_element(main, paste0("#", id))
  length(html_elements(endpoint, "figcaption.quarto-float-caption"))
}, integer(1))
table_caption_text <- vapply(expected_tables, function(id) {
  clean_text(html_element(html_element(main, paste0("#", id)), "figcaption"))
}, character(1))
figure_caption_text <- vapply(expected_figures, function(id) {
  clean_text(html_element(html_element(main, paste0("#", id)), "figcaption"))
}, character(1))

table_audit <- read_prior("table_endpoint_audit.csv")
figure_audit <- read_prior("figure_endpoint_audit.csv")
duplicate_audit <- read_prior("duplicate_id_audit.csv")
header_audit <- read_prior("table_header_reference_audit.csv")
idref_audit <- read_prior("document_idref_audit.csv")
registration_audit <- read_prior("registration_link_audit.csv")
site_audit <- read_prior("country_site_audit.csv")
prior_contracts <- read_prior("html_contracts.csv")

# Reclassify the sole known shared document hold, with scheme and origin first.
prior_links <- read_prior("reader_link_audit.csv")
hold <- !prior_links$pass &
  prior_links$href == "../../supplementary_information.html" &
  prior_links$link_text == "Supplementary information" &
  prior_links$kind == "local" &
  !prior_links$target_exists &
  !prior_links$forbidden_internal_target
prior_links$completion_classification <- ifelse(
  prior_links$pass,
  ifelse(prior_links$kind == "external", "resolved_external", "resolved_internal"),
  ifelse(hold, "DOC-001_shared_hold", "unresolved_defect")
)
prior_links$accepted_order33g <- prior_links$pass | hold
write_csv(prior_links, "reader_link_classification.csv")

current_anchors <- html_elements(document, "a[href]")
current_hrefs <- html_attr(current_anchors, "href")
current_text <- vapply(current_anchors, clean_text, character(1))
current_hold <- current_hrefs == "../../supplementary_information.html" &
  current_text == "Supplementary information"

# Semantic reversal is recomputed from the retained ledger.
semantic_summary <- utils::read.csv(
  file.path(semantic_dir, "gt_html_semantic_post_render_summary.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
ledger_path <- file.path(semantic_dir, semantic_summary$ledger_file[[1L]])
semantic_ledger <- utils::read.csv(
  ledger_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
post_raw <- read_file_raw(html_path)
reversed_raw <- apply_raw_replacements(post_raw, semantic_ledger, reverse = TRUE)
pre_document <- read_html(rawToChar(reversed_raw))
post_document <- read_html(rawToChar(post_raw))
pre_main <- html_element(pre_document, "main#quarto-document-content")
post_main <- html_element(post_document, "main#quarto-document-content")
semantic_reverse <- data.frame(
  disposition = semantic_summary$disposition,
  ledger_rows = nrow(semantic_ledger),
  expected_pre_sha256 =
    "9c3d2c9fe062756cd2a3454522bf440cc12153999621557a61eb19fa073a8e84",
  reversed_sha256 = sha256_raw(reversed_raw),
  expected_pre_bytes = 284147,
  reversed_bytes = length(reversed_raw),
  expected_post_sha256 = expected_html_sha,
  current_post_sha256 = artifact_sha256(html_path),
  expected_post_bytes = 296427,
  current_post_bytes = as.numeric(file.info(html_path)$size),
  normalized_dom_equal = identical(
    normalized_dom_without_mutable_values(pre_document),
    normalized_dom_without_mutable_values(post_document)
  ),
  visible_text_equal = identical(clean_text(pre_main), clean_text(post_main)),
  pass = semantic_summary$disposition == "REPAIRED" &&
    nrow(semantic_ledger) == 405L &&
    sha256_raw(reversed_raw) ==
      "9c3d2c9fe062756cd2a3454522bf440cc12153999621557a61eb19fa073a8e84" &&
    length(reversed_raw) == 284147 &&
    artifact_sha256(html_path) == expected_html_sha &&
    as.numeric(file.info(html_path)$size) == 296427 &&
    identical(
      normalized_dom_without_mutable_values(pre_document),
      normalized_dom_without_mutable_values(post_document)
    ) &&
    identical(clean_text(pre_main), clean_text(post_main)),
  stringsAsFactors = FALSE
)
write_csv(semantic_reverse, "semantic_reverse_verification.csv")

figure_sources_current <- file.exists(figure_audit$source_path)
source_links <- prior_links[
  grepl("artifacts/(09_tables|11_source_data)/H02", prior_links$href),
  ,
  drop = FALSE
]
main_text <- clean_text(main)
raw_error_patterns <- c(
  "Error in ", "Execution halted", "Warning message:", "Quitting from lines"
)
raw_error_hits <- vapply(
  raw_error_patterns,
  function(pattern) grepl(pattern, main_text, fixed = TRUE),
  logical(1)
)
error_nodes <- html_elements(
  main,
  ".cell-output-error, .cell-output-warning, .cell-output-stderr"
)

contracts <- data.frame(
  check = c(
    "fresh_result_html_identity",
    "table_count_and_order",
    "figure_count_and_order",
    "table_native_semantics",
    "captions_exactly_one_nonempty_per_endpoint",
    "figure_alt_and_sources",
    "unique_document_ids",
    "table_headers_530_resolve",
    "document_idrefs_552_resolve",
    "registration_links_22",
    "registration_anchors_18",
    "country_site_labels_9",
    "reader_links_with_DOC001_hold",
    "DOC001_exactly_one",
    "no_second_unresolved_link",
    "external_scheme_classification",
    "source_data_links_resolve",
    "companion_navigation",
    "no_unresolved_crossrefs",
    "no_error_warning_stderr",
    "semantic_reverse_and_dom"
  ),
  observed = c(
    artifact_sha256(html_path),
    paste(table_ids, collapse = " | "),
    paste(figure_ids, collapse = " | "),
    sum(table_audit$pass),
    sum(c(table_caption_counts, figure_caption_counts) == 1L &
      nzchar(c(table_caption_text, figure_caption_text))),
    sum(figure_audit$pass & figure_sources_current),
    nrow(duplicate_audit),
    sum(header_audit$pass),
    sum(idref_audit$pass),
    sum(registration_audit$pass),
    length(unique(registration_audit$fragment)),
    sum(site_audit$pass),
    sum(prior_links$accepted_order33g),
    sum(current_hold),
    sum(!prior_links$accepted_order33g),
    sum(prior_links$kind == "external" & prior_links$pass),
    sum(source_links$pass),
    sum(grepl("H02_analysis_preparation.html", current_hrefs, fixed = TRUE)),
    sum(grepl("@(?:fig|tbl)-", main_text, perl = TRUE)),
    length(error_nodes) + sum(raw_error_hits),
    semantic_reverse$pass
  ),
  expected = c(
    expected_html_sha,
    "15 accepted table IDs in order",
    "5 accepted figure IDs in order",
    "15",
    "20",
    "5",
    "0",
    "530",
    "552",
    "22",
    "18",
    "9",
    as.character(nrow(prior_links)),
    "1",
    "0",
    ">=1",
    as.character(nrow(source_links)),
    ">=1",
    "0",
    "0",
    "TRUE"
  ),
  pass = c(
    artifact_sha256(html_path) == expected_html_sha,
    identical(table_ids, expected_tables),
    identical(figure_ids, expected_figures),
    nrow(table_audit) == 15L && all(table_audit$pass),
    all(c(table_caption_counts, figure_caption_counts) == 1L) &&
      all(nzchar(c(table_caption_text, figure_caption_text))),
    nrow(figure_audit) == 5L && all(figure_audit$pass) &&
      all(figure_sources_current),
    nrow(duplicate_audit) == 0L,
    nrow(header_audit) == 530L && all(header_audit$pass),
    nrow(idref_audit) == 552L && all(idref_audit$pass),
    nrow(registration_audit) == 22L && all(registration_audit$pass),
    length(unique(registration_audit$fragment)) == 18L,
    nrow(site_audit) == 9L && all(site_audit$pass),
    all(prior_links$accepted_order33g),
    sum(current_hold) == 1L && sum(hold) == 1L,
    sum(!prior_links$accepted_order33g) == 0L,
    all(prior_links$pass[prior_links$kind == "external"]),
    nrow(source_links) > 0L && all(source_links$pass),
    any(grepl("H02_analysis_preparation.html", current_hrefs, fixed = TRUE)),
    !grepl("@(?:fig|tbl)-", main_text, perl = TRUE),
    length(error_nodes) == 0L && !any(raw_error_hits),
    semantic_reverse$pass
  ),
  stringsAsFactors = FALSE
)
write_csv(contracts, "nonvisual_contracts.csv")

endpoint_summary <- data.frame(
  endpoint_type = c("table", "figure"),
  count = c(length(table_ids), length(figure_ids)),
  captions_one_nonempty = c(
    sum(table_caption_counts == 1L & nzchar(table_caption_text)),
    sum(figure_caption_counts == 1L & nzchar(figure_caption_text))
  ),
  accepted_order = c(
    identical(table_ids, expected_tables),
    identical(figure_ids, expected_figures)
  ),
  pass = c(
    length(table_ids) == 15L &&
      all(table_caption_counts == 1L) && all(nzchar(table_caption_text)),
    length(figure_ids) == 5L &&
      all(figure_caption_counts == 1L) && all(nzchar(figure_caption_text))
  ),
  stringsAsFactors = FALSE
)
write_csv(endpoint_summary, "endpoint_summary.csv")

stopifnot(
  all(contracts$pass),
  all(endpoint_summary$pass),
  all(prior_contracts$pass[prior_contracts$check != "reader_links_resolve"]),
  sum(hold) == 1L,
  semantic_reverse$pass
)

cat(sprintf(
  paste0(
    "H02_ORDER33G_NONVISUAL=PASS tables=%d figures=%d headers=%d ",
    "idrefs=%d links=%d DOC001=%d registration=%d/%d\n"
  ),
  length(table_ids),
  length(figure_ids),
  nrow(header_audit),
  nrow(idref_audit),
  nrow(prior_links),
  sum(hold),
  nrow(registration_audit),
  length(unique(registration_audit$fragment))
))
