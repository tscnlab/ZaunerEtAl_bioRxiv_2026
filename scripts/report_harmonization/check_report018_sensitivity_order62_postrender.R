#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))
arguments <- commandArgs(trailingOnly = TRUE)
stopifnot(
  length(arguments) == 1L,
  arguments[[1L]] %in% c("postrender", "postqa")
)
phase <- arguments[[1L]]

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
evidence_dir <- file.path(
  root,
  paste0(
    "audit/report_harmonization/",
    "report018_sensitivity_battery_order62_render"
  )
)
stopifnot(dir.exists(evidence_dir))

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

normalize_text <- function(node) {
  trimws(gsub("[[:space:]]+", " ", xml2::xml_text(node), perl = TRUE))
}

read_inventory <- function(kind, label) {
  readr::read_csv(
    file.path(evidence_dir, paste0(kind, "_inventory_", label, ".csv")),
    show_col_types = FALSE
  )
}

compare_identity <- function(before, after, include_mtime = FALSE) {
  fields <- c("path", "type", "sha256", "bytes", "link_target")
  if (include_mtime) fields <- c(fields, "mtime_utc")
  identical(before[, fields], after[, fields])
}

build_pre <- read_inventory("build", "prerender")
build_now <- read_inventory("build", phase)
protected_pre <- read_inventory("protected", "prerender")
protected_now <- read_inventory("protected", phase)

joined <- merge(
  build_pre,
  build_now,
  by = "path",
  all = TRUE,
  suffixes = c("_pre", "_now")
)
joined$disposition <- ifelse(
  is.na(joined$type_pre),
  "ADDED",
  ifelse(
    is.na(joined$type_now),
    "REMOVED",
    ifelse(
      joined$type_pre == "file" &
        joined$type_now == "file" &
        (joined$sha256_pre != joined$sha256_now |
          joined$bytes_pre != joined$bytes_now),
      "CONTENT_CHANGED",
      ifelse(
        joined$mtime_utc_pre != joined$mtime_utc_now,
        "METADATA_ONLY",
        "UNCHANGED"
      )
    )
  )
)
delta <- joined[joined$disposition != "UNCHANGED", , drop = FALSE]
readr::write_csv(
  delta,
  file.path(evidence_dir, paste0("build_delta_", phase, ".csv"))
)
content_delta <- joined$path[
  joined$disposition %in%
    c(
      "ADDED",
      "REMOVED",
      "CONTENT_CHANGED"
    )
]
allowed_content_delta <- c(
  "notebooks/sensitivity_battery.html",
  "search.json",
  "sitemap.xml"
)
build_pass <- !length(setdiff(content_delta, allowed_content_delta)) &&
  !any(joined$disposition == "REMOVED") &&
  !any(nzchar(build_now$link_target))

protected_pass <- compare_identity(protected_pre, protected_now)

semantic_dir <- normalizePath(
  Sys.getenv("SENSITIVITY_SEMANTIC_DIR"),
  winslash = "/",
  mustWork = TRUE
)
stopifnot(
  nzchar(semantic_dir),
  !startsWith(semantic_dir, paste0(root, "/"))
)
semantic_members <- sort(list.files(
  semantic_dir,
  recursive = TRUE,
  full.names = FALSE,
  all.files = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
))
summary_name <- "gt_html_semantic_post_render_summary.csv"
summary_path <- file.path(semantic_dir, summary_name)
stopifnot(identical(semantic_members, summary_name), file.exists(summary_path))
semantic <- readr::read_csv(summary_path, show_col_types = FALSE)
target_path <- "_build/nathealth/notebooks/sensitivity_battery.html"
target_sha <- sha256_file(target_path)
semantic_pass <- nrow(semantic) == 1L &&
  semantic$target[[1L]] == target_path &&
  semantic$disposition[[1L]] == "NO_GT" &&
  semantic$pre_sha256[[1L]] == target_sha &&
  semantic$post_sha256[[1L]] == target_sha &&
  semantic$table_count[[1L]] == 0L &&
  semantic$id_count[[1L]] == 0L &&
  semantic$headers_count[[1L]] == 0L &&
  semantic$total_substitutions[[1L]] == 0L &&
  !nzchar(semantic$ledger_file[[1L]])

document <- xml2::read_html(target_path, encoding = "UTF-8")
main <- xml2::xml_find_all(document, "//main[@id='quarto-document-content']")
headings <- xml2::xml_find_all(main, ".//*[self::h1 or self::h2]")
heading_text <- vapply(headings, normalize_text, character(1))
expected_headings <- c(
  "Planned sensitivity checks",
  "Purpose",
  "Manuscript-prepared-data sensitivity",
  "What this notebook uses and produces"
)
ids <- xml2::xml_attr(xml2::xml_find_all(document, "//*[@id]"), "id")
errors <- xml2::xml_find_all(
  document,
  paste0(
    "//*[contains(@class, 'cell-output-error') or ",
    "contains(@class, 'cell-output-warning') or ",
    "contains(@class, 'cell-output-stderr') or ",
    "contains(@class, 'quarto-unresolved-ref')]"
  )
)
code_fold <- xml2::xml_find_all(
  main,
  ".//details[contains(concat(' ', normalize-space(@class), ' '), ' code-fold ')]"
)
dom_pass <- length(main) == 1L &&
  identical(heading_text, expected_headings) &&
  length(xml2::xml_find_all(main, ".//table")) == 0L &&
  length(xml2::xml_find_all(main, ".//figure")) == 0L &&
  length(errors) == 0L &&
  !anyDuplicated(ids) &&
  length(code_fold) == 1L &&
  grepl("eval: false", normalize_text(code_fold[[1L]]), fixed = TRUE) &&
  length(xml2::xml_find_all(
    document,
    "//meta[@name='generator' and @content='quarto-1.9.37']"
  )) ==
    1L

xpath_literal <- function(value) {
  if (!grepl("'", value, fixed = TRUE)) return(paste0("'", value, "'"))
  if (!grepl('"', value, fixed = TRUE)) return(paste0('"', value, '"'))
  pieces <- strsplit(value, "'", fixed = TRUE)[[1L]]
  paste0("concat('", paste(pieces, collapse = "', \"'\", '"), "')")
}

hrefs <- xml2::xml_attr(xml2::xml_find_all(document, "//a[@href]"), "href")
internal <- !grepl("^(https?:|mailto:|tel:|javascript:|data:|#)", hrefs)
internal_hrefs <- hrefs[internal]
link_rows <- lapply(internal_hrefs, function(href) {
  base <- sub("[?#].*$", "", href, perl = TRUE)
  fragment <- if (grepl("#", href, fixed = TRUE)) {
    sub("^[^#]*#", "", href, perl = TRUE)
  } else {
    ""
  }
  resolved <- normalizePath(
    file.path(dirname(target_path), base),
    winslash = "/",
    mustWork = FALSE
  )
  exists <- file.exists(resolved)
  fragment_ok <- TRUE
  if (exists && nzchar(fragment) && grepl("[.]html?$", resolved)) {
    linked <- xml2::read_html(resolved)
    fragment_ok <- length(xml2::xml_find_all(
      linked,
      paste0("//*[@id=", xpath_literal(fragment), "]")
    )) ==
      1L
  }
  data.frame(
    href = href,
    resolved = resolved,
    exists = exists,
    fragment = fragment,
    fragment_resolves = fragment_ok,
    stringsAsFactors = FALSE
  )
})
links <- if (length(link_rows)) do.call(rbind, link_rows) else data.frame()
link_pass <- nrow(links) > 0L &&
  all(links$exists) &&
  all(links$fragment_resolves)
readr::write_csv(
  links,
  file.path(evidence_dir, paste0("link_audit_", phase, ".csv"))
)

active <- xml2::xml_find_all(
  document,
  paste0(
    "//a[contains(@href, 'sensitivity_battery.html') and ",
    "(contains(concat(' ', normalize-space(@class), ' '), ' active ') or ",
    "@aria-current='page')]"
  )
)
navigation_pass <- length(active) == 1L &&
  file.exists("_build/nathealth/supplementary_information.html") &&
  file.exists("_build/nathealth/notebooks/hypotheses/H11.html")

checks <- data.frame(
  check = c(
    "build_delta_allowed",
    "protected_inventory_exact",
    "semantic_no_gt",
    "target_dom_contract",
    "internal_links_resolve",
    "navigation_routes_present"
  ),
  pass = c(
    build_pass,
    protected_pass,
    semantic_pass,
    dom_pass,
    link_pass,
    navigation_pass
  ),
  detail = c(
    paste(content_delta, collapse = "; "),
    sprintf("members=%d", nrow(protected_now)),
    sprintf("target=%s sha=%s", semantic$target[[1L]], target_sha),
    paste(heading_text, collapse = " | "),
    sprintf("internal=%d", nrow(links)),
    sprintf("active=%d H11=1 supplementary=1", length(active))
  ),
  stringsAsFactors = FALSE
)
readr::write_csv(
  checks,
  file.path(evidence_dir, paste0("postrender_checks_", phase, ".csv"))
)
stopifnot(nrow(checks) == 6L, all(checks$pass))

cat(sprintf(
  paste0(
    "REPORT018_SENSITIVITY_ORDER62_%s=PASS checks=%d/%d build=%d ",
    "protected=%d semantic=NO_GT links=%d html=%s R=%s\n"
  ),
  toupper(phase),
  sum(checks$pass),
  nrow(checks),
  nrow(build_now),
  nrow(protected_now),
  nrow(links),
  target_sha,
  as.character(getRversion())
))
