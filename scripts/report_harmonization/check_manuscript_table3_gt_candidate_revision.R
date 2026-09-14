#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(xml2)
})

if (!identical(as.character(getRversion()), "4.6.1")) stop("R 4.6.1 required.")
root <- normalizePath(Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/", mustWork = TRUE
)
setwd(root)

asset_root <- "audit/manuscript_nature_health/figure_table_selection_assets"
candidate_dir <- paste0(
  asset_root, "/",
  "table3_gt_candidate_revision"
)
candidate_path <- file.path(candidate_dir, "tbl-plan-h01-metric-synthesis-candidate.html")
inventory_path <- file.path(candidate_dir, "table3_candidate_content_inventory.csv")
source_path <- paste0(
  "audit/manuscript_nature_health/figure_table_selection_assets/",
  "tbl-plan-h01-metric-synthesis.html"
)

norm <- function(x) trimws(gsub("[[:space:]]+", " ", x))
fdr_reader <- function(x) {
  x <- sub("^FDR-supported", "supported", x)
  sub("^Not retained", "not supported", x)
}
line <- function(label, value) norm(paste(label, value))

inventory <- read.csv(inventory_path, check.names = FALSE, stringsAsFactors = FALSE)
if (nrow(inventory) != 17L) stop("Expected 17 inventory rows.")
values <- strsplit(inventory$source_values, "␟", fixed = TRUE)
if (!all(lengths(values) == 16L)) stop("Expected 16 accepted source cells per row.")

expected <- lapply(values, function(x) c(
  norm(x[[1L]]),
  norm(x[[2L]]),
  norm(paste(
    line("Unit", x[[3L]]), line("Median", x[[4L]]), line("IQR", x[[5L]]),
    line("Participants", x[[6L]]), line("Days", x[[7L]])
  )),
  "",
  norm(paste(line("FDR", fdr_reader(x[[9L]])), line("Part R-squared", x[[10L]]))),
  norm(paste(
    line("Estimate", x[[11L]]), line("FDR", fdr_reader(x[[12L]])),
    line("Part R-squared", x[[13L]])
  )),
  norm(paste(
    line("Marginal", x[[14L]]), line("Conditional", x[[15L]]),
    line("Participant-associated", x[[16L]])
  ))
))

document <- read_html(candidate_path)
rows <- xml_find_all(document, "//tbody/tr[not(.//*[contains(@class,'gt_group_heading')])]")
observed <- lapply(rows, function(row) norm(xml_text(xml_children(row))))
canonical_cells <- function(x) gsub("[[:space:]]+", "", x)

checks <- data.frame(
  check = c(
    "native_gt", "rows", "exact_display_cells", "groups", "images",
    "participants_labels", "no_duplicate_fdr", "supported_lines_bold",
    "column_widths", "compact_rows", "semantic_scopes", "source_boundary",
    "descriptive_group_order", "descriptive_metric_order"
  ),
  pass = FALSE,
  detail = "",
  stringsAsFactors = FALSE
)
set_check <- function(name, pass, detail) {
  index <- match(name, checks$check)
  checks$pass[[index]] <<- isTRUE(pass)
  checks$detail[[index]] <<- detail
}

set_check("native_gt", length(xml_find_all(document, "//table[contains(@class,'gt_table')]")) == 1L,
  "one native gt table")
set_check("rows", length(rows) == 17L, paste0("rows=", length(rows)))
set_check("exact_display_cells", identical(lapply(expected, canonical_cells), lapply(observed, canonical_cells)),
  "accepted content preserved with only authorized reader-label substitutions")
groups <- unique(norm(xml_text(xml_find_all(document, "//*[contains(@class,'gt_group_heading')]"))))
set_check("groups", identical(groups, unique(inventory$metric_family)), paste(groups, collapse = " | "))
images <- xml_find_all(document, "//img[contains(@class,'metric-density-thumb')]")
set_check("images", length(images) == 17L && identical(xml_attr(images, "src"), inventory$image_src) &&
    identical(xml_attr(images, "alt"), inventory$image_alt), "17 exact image source and alt identities")
text <- norm(xml_text(document))
participant_labels <- xml_find_all(document, "//span[contains(@class,'mini-label') and normalize-space(.)='Participants']")
set_check("participants_labels", length(participant_labels) == 17L,
  "17 Participants labels")
set_check("no_duplicate_fdr", !grepl("FDR FDR", text, fixed = TRUE) && !grepl("Not retained", text, fixed = TRUE),
  "reader decisions use FDR supported / FDR not supported")
supported_source <- sum(vapply(values, function(x) {
  sum(grepl("^FDR-supported", x[c(9L, 12L)]))
}, integer(1)))
bold_supported <- xml_find_all(document, "//strong[.//span[contains(@class,'mini-label') and normalize-space(.)='FDR']]")
set_check("supported_lines_bold", length(bold_supported) == supported_source,
  paste0("bold=", length(bold_supported), "; expected=", supported_source))
html <- paste(readLines(candidate_path, warn = FALSE), collapse = "\n")
widths <- c("135px", "205px", "135px", "155px", "125px", "205px", "200px")
set_check("column_widths", all(vapply(widths, grepl, logical(1), x = html, fixed = TRUE)),
  paste(widths, collapse = " | "))
set_check("compact_rows", grepl("height:90px", html, fixed = TRUE) &&
    grepl("height:82px", html, fixed = TRUE) && grepl("height:24px", html, fixed = TRUE),
  "90-px rows, 82-px thumbnails, 24-px group headings")
scopes <- xml_find_all(document, "//th[@scope='col' or @scope='row' or @scope='rowgroup']")
set_check("semantic_scopes", length(scopes) > 0L, paste0("scoped_headers=", length(scopes)))
source_document <- read_html(source_path)
source_images <- xml_find_all(source_document, "//img[contains(@class,'metric-density-thumb')]")
set_check("source_boundary", length(source_images) == 17L, "accepted source remains present and readable")

descriptive_document <- read_html(file.path(
  asset_root, "tbl-near-eye-metrics.html"
))
descriptive_groups <- unique(norm(xml_text(xml_find_all(
  descriptive_document, "//*[contains(@class,'gt_group_heading')]"
))))
descriptive_rows <- xml_find_all(
  descriptive_document,
  "//tbody/tr[not(.//*[contains(@class,'gt_group_heading')])]"
)
descriptive_metrics <- vapply(descriptive_rows, function(row) {
  norm(xml_text(xml_find_first(row, "./th[1]//span[1]")))
}, character(1))
candidate_metrics <- norm(xml_text(xml_find_all(
  document,
  "//tbody/tr[not(.//*[contains(@class,'gt_group_heading')])]//th[contains(@class,'gt_stub')]"
)))
canonical_metric <- function(value) sub(" geometric mean$", " mean", value)
set_check(
  "descriptive_group_order",
  identical(groups, descriptive_groups),
  paste(groups, collapse = " | ")
)
set_check(
  "descriptive_metric_order",
  identical(canonical_metric(candidate_metrics), descriptive_metrics),
  paste(candidate_metrics, collapse = " | ")
)

results_path <- file.path(candidate_dir, "table3_revision_checks.csv")
write.csv(checks, results_path, row.names = FALSE, na = "")
if (!all(checks$pass)) {
  print(checks[!checks$pass, , drop = FALSE])
  stop("Table 3 revision checks failed.")
}
cat("TABLE3_REVISION_CHECK=PASS checks=", nrow(checks), "\n", sep = "")
