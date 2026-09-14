#!/usr/bin/env Rscript

stopifnot(identical(as.character(getRversion()), "4.6.1"))
suppressPackageStartupMessages(library(xml2))

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
build_root <- normalizePath(
  file.path(root, "_build/nathealth"),
  winslash = "/",
  mustWork = TRUE
)
target <- file.path(build_root, "supplementary_information.html")
evidence_dir <- file.path(
  root,
  "audit/report_harmonization/report018_supplementary_information_order38"
)
stopifnot(file.exists(target), dir.exists(evidence_dir))

document <- read_html(target)
normalize_text <- function(node) {
  trimws(gsub("[[:space:]]+", " ", xml_text(node), perl = TRUE))
}

expected_headings <- c(
  "Supplementary Methods",
  "Preregistration and deviations",
  "Hypothesis-level results",
  sprintf("H%02d", 1:11),
  "Sensor-placement analysis",
  "Sensitivity analyses",
  "Supplementary figures",
  "Supplementary tables",
  "References"
)
observed_headings <- vapply(
  xml_find_all(document, "//main[@id='quarto-document-content']//section/*[self::h1 or self::h2]"),
  normalize_text,
  character(1)
)

title_nodes <- xml_find_all(document, "//h1[contains(concat(' ', normalize-space(@class), ' '), ' title ')]")
active_nodes <- xml_find_all(
  document,
  paste0(
    "//a[contains(concat(' ', normalize-space(@class), ' '), ' active ') ",
    "and contains(@href, 'supplementary_information.html')]"
  )
)
gt_tables <- xml_find_all(
  document,
  "//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
figures <- xml_find_all(document, "//main[@id='quarto-document-content']//figure")
error_nodes <- xml_find_all(
  document,
  paste0(
    "//*[contains(concat(' ', normalize-space(@class), ' '), ' cell-output-error ') ",
    "or contains(concat(' ', normalize-space(@class), ' '), ' cell-output-warning ') ",
    "or contains(concat(' ', normalize-space(@class), ' '), ' quarto-error ') ",
    "or contains(concat(' ', normalize-space(@class), ' '), ' stderr ')]"
  )
)

contracts <- data.frame(
  contract = c(
    "title_exact",
    "source_headings_exact",
    "active_navigation_exactly_one",
    "native_gt_tables_zero",
    "figures_zero",
    "error_warning_stderr_nodes_zero",
    "generator_quarto_1_9_37"
  ),
  pass = c(
    length(title_nodes) == 1L && identical(normalize_text(title_nodes[[1L]]), "Supplementary Information"),
    identical(observed_headings, expected_headings),
    length(active_nodes) == 1L,
    length(gt_tables) == 0L,
    length(figures) == 0L,
    length(error_nodes) == 0L,
    length(xml_find_all(document, "//meta[@name='generator' and @content='quarto-1.9.37']")) == 1L
  ),
  observed = c(
    if (length(title_nodes)) normalize_text(title_nodes[[1L]]) else "",
    paste(observed_headings, collapse = " | "),
    as.character(length(active_nodes)),
    as.character(length(gt_tables)),
    as.character(length(figures)),
    as.character(length(error_nodes)),
    as.character(length(xml_find_all(document, "//meta[@name='generator' and @content='quarto-1.9.37']")))
  ),
  stringsAsFactors = FALSE
)
stopifnot(all(contracts$pass))
write.csv(
  contracts,
  file.path(evidence_dir, "html_contracts.csv"),
  row.names = FALSE,
  na = ""
)

anchors <- xml_find_all(document, "//a[@href]")
hrefs <- xml_attr(anchors, "href")
labels <- vapply(anchors, normalize_text, character(1))
labels[!nzchar(labels)] <- xml_attr(anchors[!nzchar(labels)], "aria-label")
labels[is.na(labels)] <- ""

classify_href <- function(href) {
  if (grepl("^#cb[0-9]+-[0-9]+$", href, perl = TRUE)) {
    return("generated_code_line_anchor")
  }
  if (grepl("^(https?:|mailto:|tel:)", href, perl = TRUE)) {
    return("external")
  }
  if (grepl("^(javascript:|data:)", href, perl = TRUE)) {
    return("non_file_action")
  }
  "internal"
}

resolve_internal <- function(href) {
  base_part <- sub("[?#].*$", "", href, perl = TRUE)
  fragment <- if (grepl("#", href, fixed = TRUE)) {
    sub("^[^#]*#", "", href, perl = TRUE)
  } else {
    ""
  }
  if (!nzchar(base_part)) {
    resolved <- target
  } else if (startsWith(base_part, "/")) {
    resolved <- file.path(build_root, sub("^/+", "", base_part))
  } else {
    resolved <- file.path(dirname(target), base_part)
  }
  resolved <- normalizePath(resolved, winslash = "/", mustWork = FALSE)
  within_root <- identical(resolved, build_root) ||
    startsWith(resolved, paste0(build_root, "/"))
  exists <- file.exists(resolved)
  fragment_exists <- TRUE
  if (exists && nzchar(fragment) && grepl("\\.html$", resolved, perl = TRUE)) {
    linked <- if (identical(resolved, normalizePath(target, winslash = "/", mustWork = TRUE))) {
      document
    } else {
      read_html(resolved)
    }
    fragment_exists <- length(xml_find_all(
      linked,
      sprintf("//*[@id=%s]", xpath_literal(fragment))
    )) == 1L
  }
  c(
    resolved = resolved,
    within_root = as.character(within_root),
    exists = as.character(exists),
    fragment = fragment,
    fragment_exists = as.character(fragment_exists)
  )
}

xpath_literal <- function(value) {
  if (!grepl("'", value, fixed = TRUE)) {
    return(paste0("'", value, "'"))
  }
  if (!grepl('"', value, fixed = TRUE)) {
    return(paste0('"', value, '"'))
  }
  pieces <- strsplit(value, "'", fixed = TRUE)[[1L]]
  paste0("concat('", paste(pieces, collapse = "', \"'\", '"), "')")
}

classes <- vapply(hrefs, classify_href, character(1))
resolved <- matrix("", nrow = length(hrefs), ncol = 5L)
colnames(resolved) <- c("resolved", "within_root", "exists", "fragment", "fragment_exists")
for (index in which(classes == "internal")) {
  resolved[index, ] <- resolve_internal(hrefs[[index]])
}

links <- data.frame(
  href = hrefs,
  label = labels,
  classification = classes,
  resolved = resolved[, "resolved"],
  within_root = resolved[, "within_root"],
  exists = resolved[, "exists"],
  fragment = resolved[, "fragment"],
  fragment_exists = resolved[, "fragment_exists"],
  stringsAsFactors = FALSE
)
internal <- links$classification == "internal"
reader_action <- links$classification != "generated_code_line_anchor"
stopifnot(
  all(nzchar(links$label[reader_action])),
  all(links$within_root[internal] == "TRUE"),
  all(links$exists[internal] == "TRUE"),
  all(links$fragment_exists[internal] == "TRUE")
)
write.csv(
  links,
  file.path(evidence_dir, "internal_link_audit.csv"),
  row.names = FALSE,
  na = ""
)

cat(sprintf(
  paste0(
    "html_contracts=%d/%d headings=%d tables=%d figures=%d ",
    "links=%d internal=%d external=%d\n"
  ),
  sum(contracts$pass),
  nrow(contracts),
  length(observed_headings),
  length(gt_tables),
  length(figures),
  nrow(links),
  sum(internal),
  sum(classes == "external")
))
