# REPORT-017 display-only acceptance checks for the Descriptives page.

find_project_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (all(file.exists(file.path(current, c("_quarto.yml", "renv.lock"))))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not locate the project root", call. = FALSE)
    }
    current <- parent
  }
}

assert_true <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
}

root <- find_project_root()
source_path <- file.path(root, "notebooks", "descriptives.qmd")
html_path <- file.path(
  root, "_build", "nathealth", "notebooks", "descriptives.html"
)

assert_true(
  getRversion() >= numeric_version("4.6.1") &&
    getRversion() < numeric_version("4.7.0"),
  "REPORT-017 Descriptives checks require R 4.6.1"
)
assert_true(file.exists(source_path), "Descriptives source is missing")
assert_true(file.exists(html_path), "Target-rendered Descriptives HTML is missing")
assert_true(requireNamespace("xml2", quietly = TRUE), "xml2 is unavailable")

source_lines <- readLines(source_path, warn = FALSE, encoding = "UTF-8")
source_text <- paste(source_lines, collapse = "\n")

required_source_links <- c(
  "[Preparation 01](preparation/01_import_state_alignment.qmd)",
  "[Preparation 02](preparation/02_coverage_sample_flow.qmd)"
)
for (link in required_source_links) {
  assert_true(
    grepl(link, source_text, fixed = TRUE),
    paste("Missing dynamic source link:", link)
  )
}
assert_true(
  !grepl("\\[[^]]+\\]\\([^)]*[.]html(?:[#?][^)]*)?\\)", source_text, perl = TRUE),
  "A hard-coded internal HTML link remains in the Descriptives source"
)
assert_true(
  !grepl("file://|_build/|/Users/", source_text, perl = TRUE),
  "A forbidden local or build path remains in the Descriptives source"
)

document <- xml2::read_html(html_path, encoding = "UTF-8")

required_tables <- c(
  "tbl-participant-site" = NA_integer_,
  "tbl-near-eye-metrics" = NA_integer_,
  "tbl-recommendation-context" = NA_integer_,
  "tbl-descriptive-sample-flow" = 8L,
  "tbl-descriptive-comparison-summary" = 6L,
  "tbl-descriptive-visual-export-comparison" = 10L,
  "tbl-descriptive-figure-contract" = 6L
)

for (identifier in names(required_tables)) {
  container <- xml2::xml_find_first(
    document,
    sprintf("//*[@id='%s']", identifier)
  )
  assert_true(
    !inherits(container, "xml_missing"),
    paste("Rendered identifier is missing:", identifier)
  )
  table <- xml2::xml_find_first(
    container,
    ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
  )
  assert_true(
    !inherits(table, "xml_missing"),
    paste("Rendered endpoint is not a semantic native gt table:", identifier)
  )
  expected_rows <- unname(required_tables[[identifier]])
  if (!is.na(expected_rows)) {
    body_rows <- xml2::xml_find_all(
      table,
      ".//tbody/tr[td[contains(concat(' ', normalize-space(@class), ' '), ' gt_row ')] or th[contains(concat(' ', normalize-space(@class), ' '), ' gt_row ')]]"
    )
    assert_true(
      length(body_rows) == expected_rows,
      paste(
        identifier,
        "has",
        length(body_rows),
        "rendered data rows; expected",
        expected_rows
      )
    )
  }
}

participant_table <- xml2::xml_find_first(
  document,
  "//*[@id='tbl-participant-site']"
)
participant_table_text <- xml2::xml_text(participant_table)
assert_true(
  !grepl("submitted grouping", participant_table_text, fixed = TRUE),
  "The main participant table exposes construction-history language"
)
assert_true(
  !grepl("Near-eye", participant_table_text, fixed = TRUE),
  "The main participant table uses the unapproved hyphenated placement label"
)

overview <- xml2::xml_find_first(document, "//*[@id='fig-descriptive-overview']")
assert_true(
  !inherits(overview, "xml_missing"),
  "The main Descriptives figure identifier is missing"
)
overview_image <- xml2::xml_find_first(overview, ".//img")
assert_true(
  !inherits(overview_image, "xml_missing"),
  "The main Descriptives figure image is missing"
)
assert_true(
  nzchar(trimws(xml2::xml_attr(overview_image, "alt"))),
  "The main Descriptives figure has empty alt text"
)
assert_true(
  grepl("descriptive_overview[.]png", xml2::xml_attr(overview_image, "src")),
  "The main Descriptives figure does not use the accepted stored PNG"
)

main_content <- xml2::xml_find_first(document, "//main")
if (inherits(main_content, "xml_missing")) {
  main_content <- document
}
main_text <- xml2::xml_text(main_content)
assert_true(
  !grepl("submitted grouping", main_text, fixed = TRUE),
  "Rendered main content exposes submitted-analysis construction history"
)
assert_true(
  !grepl("Near-eye", main_text, fixed = TRUE),
  "Rendered main content uses the unapproved hyphenated placement label"
)
hrefs <- xml2::xml_attr(xml2::xml_find_all(main_content, ".//a[@href]"), "href")
anchors <- xml2::xml_find_all(main_content, ".//a[@href]")
anchor_text <- trimws(xml2::xml_text(anchors))
expected_preparation_links <- c(
  "Preparation 01" = "01_import_state_alignment.html",
  "Preparation 02" = "02_coverage_sample_flow.html"
)
for (label in names(expected_preparation_links)) {
  index <- which(anchor_text == label)
  assert_true(
    length(index) == 1L,
    paste("Rendered link is missing or duplicated:", label)
  )
  href <- hrefs[[index]]
  resolved_path <- file.path(
    dirname(html_path),
    sub("[?#].*$", "", href, perl = TRUE)
  )
  assert_true(
    basename(resolved_path) == expected_preparation_links[[label]] &&
      file.exists(resolved_path),
    paste(label, "does not resolve to its accepted profile-rendered page")
  )
}
assert_true(
  !any(grepl("[.]qmd(?:[#?].*)?$|^file:|_build|/Users/", hrefs, perl = TRUE)),
  "A rendered reader link exposes a QMD, local file, build, or absolute path"
)

error_nodes <- xml2::xml_find_all(
  document,
  "//*[contains(concat(' ', normalize-space(@class), ' '), ' cell-output-error ') or contains(concat(' ', normalize-space(@class), ' '), ' cell-output-warning ')]"
)
assert_true(length(error_nodes) == 0L, "The rendered page contains an error or warning block")

cat("REPORT-017 Descriptives render contract PASS\n")
