#!/usr/bin/env Rscript

# Bounded, no-render implementation for REPORT-018 Order 67a. This script
# performs structural file and DOM verification only. It does not source a
# research QMD or calculate a scientific result.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(digest)
  library(jsonlite)
  library(readr)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

arguments <- commandArgs(trailingOnly = TRUE)
stopifnot(length(arguments) == 1L)
mode <- arguments[[1L]]
stopifnot(mode %in% c("candidate", "promote", "postflight"))

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(project_root)

evidence_rel <- paste0(
  "audit/report_harmonization/",
  "navigation_mobile_toc_collapse_repair_2026_09_02/",
  "order67a_clone_state_repair"
)
evidence_dir <- file.path(project_root, evidence_rel)
stopifnot(dir.exists(evidence_dir))

script_path <- file.path(evidence_dir, "order67a_transform_verify_promote.R")
script_seal_path <- file.path(evidence_dir, "implementation_script_seal.csv")
candidate_root <- normalizePath(
  Sys.getenv("ORDER67A_CANDIDATE_ROOT"),
  winslash = "/",
  mustWork = TRUE
)
backup_root <- normalizePath(
  Sys.getenv("ORDER67A_BACKUP_ROOT"),
  winslash = "/",
  mustWork = TRUE
)
candidate_build <- file.path(candidate_root, "candidate_build")
candidate_include <- file.path(
  candidate_root,
  "candidate_include",
  "nathealth-mobile-toc.html"
)

sha256_file <- function(path) {
  digest::digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}

sha256_text <- function(text) {
  digest::digest(charToRaw(text), algo = "sha256", serialize = FALSE)
}

file_bytes <- function(path) {
  unname(as.numeric(file.info(path)$size))
}

read_raw_file <- function(path) {
  size <- file_bytes(path)
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, what = "raw", n = size)
}

read_raw_text <- function(path) {
  rawToChar(read_raw_file(path))
}

write_raw_atomic <- function(value, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(paste0(basename(path), "."), tmpdir = dirname(path))
  connection <- file(temporary, open = "wb")
  is_open <- TRUE
  on.exit({
    if (is_open) close(connection)
    if (file.exists(temporary)) unlink(temporary)
  }, add = TRUE)
  writeBin(value, connection)
  close(connection)
  is_open <- FALSE
  if (!file.rename(temporary, path)) {
    stop("Atomic file replacement failed for ", path, call. = FALSE)
  }
  invisible(path)
}

write_text_atomic <- function(value, path) {
  write_raw_atomic(charToRaw(enc2utf8(value)), path)
}

copy_file_atomic <- function(source, target) {
  value <- read_raw_file(source)
  write_raw_atomic(value, target)
  stopifnot(identical(sha256_file(source), sha256_file(target)))
  invisible(target)
}

count_fixed <- function(pattern, text) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) return(0L)
  length(matches)
}

require_file <- function(path, sha256, bytes = NULL) {
  stopifnot(file.exists(path), !dir.exists(path), !nzchar(Sys.readlink(path)))
  stopifnot(identical(sha256_file(path), sha256))
  if (!is.null(bytes)) stopifnot(file_bytes(path) == bytes)
  invisible(TRUE)
}

inventory_files <- function(root) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  members <- sort(list.files(
    root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  ))
  stopifnot(!any(nzchar(Sys.readlink(members))))
  data.frame(
    path = substring(members, nchar(root) + 2L),
    sha256 = unname(vapply(members, sha256_file, character(1))),
    bytes = unname(as.numeric(file.info(members)$size)),
    stringsAsFactors = FALSE
  )
}

symlink_count <- function(root) {
  members <- list.files(
    root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  )
  sum(nzchar(Sys.readlink(members)))
}

same_inventory <- function(first, second) {
  first <- first[order(first$path), c("path", "sha256", "bytes")]
  second <- second[order(second$path), c("path", "sha256", "bytes")]
  rownames(first) <- NULL
  rownames(second) <- NULL
  identical(first$path, second$path) &&
    identical(first$sha256, second$sha256) &&
    identical(as.numeric(first$bytes), as.numeric(second$bytes))
}

read_manifest_exact <- function(path, expected_rows) {
  manifest <- readr::read_csv(path, show_col_types = FALSE)
  stopifnot(nrow(manifest) == expected_rows, !anyDuplicated(manifest$path))
  stopifnot(!path %in% manifest$path)
  stopifnot(all(file.exists(manifest$path)), !any(dir.exists(manifest$path)))
  observed_hashes <- vapply(manifest$path, sha256_file, character(1))
  observed_bytes <- unname(as.numeric(file.info(manifest$path)$size))
  stopifnot(
    identical(unname(observed_hashes), unname(manifest$sha256)),
    identical(observed_bytes, as.numeric(manifest$bytes))
  )
  manifest
}

script_seal <- readr::read_csv(script_seal_path, show_col_types = FALSE)
stopifnot(
  nrow(script_seal) == 1L,
  identical(script_seal$path[[1L]], file.path(evidence_rel, basename(script_path))),
  identical(script_seal$sha256[[1L]], sha256_file(script_path)),
  script_seal$bytes[[1L]] == file_bytes(script_path)
)

order_path <- file.path(
  project_root,
  "audit/report_harmonization/owner_orders/67a_nathealth_mobile_toc_clone_state_repair_and_h06_completion.md"
)
dispatch_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_navigation_order67a_dispatch_manifest.csv"
)
stop_acceptance_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_navigation_order67_stop_independent_acceptance.md"
)
stop_acceptance_manifest_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_navigation_order67_stop_independent_acceptance_manifest.csv"
)
duplicate_clarification_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_navigation_order67a_duplicate_id_gate_clarification.md"
)
duplicate_clarification_manifest_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_navigation_order67a_duplicate_id_gate_clarification_manifest.csv"
)
require_file(
  order_path,
  "4a04f727535247fb6a8ce5e54ab002d9b0f21fb78ee9d36097f27f1eac9001c4",
  11296
)
require_file(
  dispatch_path,
  "53086ca8e49d1e998b0cc3b2f37b2616c98a2dd8bdb083622259da653585b174"
)
require_file(
  stop_acceptance_path,
  "9bbae3bfcbfdba1746a17b166d4cdbb62a52da9a1409ac6afd758a836a3a444e",
  3666
)
require_file(
  stop_acceptance_manifest_path,
  "d46ee325d53d52075dfda69fd1de9465771bd1a033d1429f280f14aeeee4cc97",
  3673
)
require_file(
  duplicate_clarification_path,
  "a8cf8f784a05d8a2eda59b24ee1cb5c7c918bb97d58ac7cbd7102539cb8fe989",
  2000
)
require_file(
  duplicate_clarification_manifest_path,
  "0887c744fd98d0718a13429e3203b76465ee201976a1b3d81a2ae44179973d82"
)
if (mode %in% c("candidate", "promote")) {
  dispatch <- read_manifest_exact(dispatch_path, 30L)
  stop_acceptance_manifest <- read_manifest_exact(stop_acceptance_manifest_path, 19L)
  duplicate_clarification_manifest <- read_manifest_exact(
    duplicate_clarification_manifest_path,
    8L
  )
} else {
  dispatch <- readr::read_csv(dispatch_path, show_col_types = FALSE)
  stop_acceptance_manifest <- readr::read_csv(
    stop_acceptance_manifest_path,
    show_col_types = FALSE
  )
  duplicate_clarification_manifest <- readr::read_csv(
    duplicate_clarification_manifest_path,
    show_col_types = FALSE
  )
  stopifnot(
    nrow(dispatch) == 30L,
    nrow(stop_acceptance_manifest) == 19L,
    nrow(duplicate_clarification_manifest) == 8L,
    !anyDuplicated(dispatch$path),
    !anyDuplicated(stop_acceptance_manifest$path),
    !anyDuplicated(duplicate_clarification_manifest$path)
  )
}

fail_manifest_path <- file.path(
  project_root,
  paste0(
    "audit/report_harmonization/navigation_mobile_toc_collapse_repair_2026_09_02/",
    "order67_fail_closed_manifest.csv"
  )
)
fail_manifest <- if (mode %in% c("candidate", "promote")) {
  read_manifest_exact(fail_manifest_path, 43L)
} else {
  value <- readr::read_csv(fail_manifest_path, show_col_types = FALSE)
  stopifnot(nrow(value) == 43L, !anyDuplicated(value$path))
  value
}

process_gate_path <- file.path(evidence_dir, "preflight_process_gate.csv")
process_gate <- readr::read_csv(process_gate_path, show_col_types = FALSE)
stopifnot(
  nrow(process_gate) == 1L,
  identical(process_gate$status[[1L]], "PASS"),
  process_gate$conflicting_process_count[[1L]] == 0L
)

baseline_path <- file.path(
  project_root,
  paste0(
    "audit/hypotheses/H06/employment_eligibility_sensitivity/",
    "order66b_result_no_rerender_completion/post_qa_build_inventory.csv"
  )
)
require_file(
  baseline_path,
  "8d00db3d2a7bfe8f17526cee08027bafd83f99bb7ad0e36c73e3e46cada5f355"
)
baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)
baseline <- baseline[order(baseline$path), c("path", "sha256", "bytes")]
rownames(baseline) <- NULL
stopifnot(nrow(baseline) == 892L, !anyDuplicated(baseline$path))

build_root <- file.path(project_root, "_build/nathealth")
include_path <- file.path(project_root, "_includes/nathealth-mobile-toc.html")
source_css_path <- file.path(project_root, "styles-nathealth.css")
build_css_path <- file.path(build_root, "styles-nathealth.css")
corpus_manifest_path <- file.path(
  project_root,
  "audit/report_harmonization/phase4_corpus_manifest.csv"
)

include_pre_sha <- "926a5fc051f032100714ae01b53c5ba2937c91ff2406ab5354484bf8fd7f553d"
include_post_sha <- "153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980"
css_sha <- "051d9468f636df71e2408687661369a443029407426fef98850ff56def9aac87"
corpus_pre_sha <- "c42c326230818a93aa89322155b933c2f536f09bd447ab09b72f934fba75e76f"
corpus_post_sha <- "5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b"

manifest_pre_path <- if (
  identical(mode, "postflight") &&
    file.exists(file.path(evidence_dir, "corpus_manifest_pre.csv"))
) {
  file.path(evidence_dir, "corpus_manifest_pre.csv")
} else {
  corpus_manifest_path
}
manifest_pre <- readr::read_csv(manifest_pre_path, show_col_types = FALSE)
stopifnot(
  nrow(manifest_pre) == 37L,
  !anyDuplicated(manifest_pre$expected_html),
  !anyDuplicated(manifest_pre$source)
)
routes <- sub("^_build/nathealth/", "", manifest_pre$expected_html)
stopifnot(length(routes) == 37L, !anyDuplicated(routes))

include_pre_path <- if (
  identical(mode, "postflight") &&
    file.exists(file.path(
      backup_root,
      "preimages",
      "_includes/nathealth-mobile-toc.html"
    ))
) {
  file.path(
    backup_root,
    "preimages",
    "_includes/nathealth-mobile-toc.html"
  )
} else {
  include_path
}
include_pre <- read_raw_text(include_pre_path)
clone_line <- "    const list = sourceList.cloneNode(true);\n"
clone_fix <- paste0(
  clone_line,
  "\n",
  "    list.classList.remove(\"collapse\");\n",
  "    list.querySelectorAll(\".collapse\").forEach((element) => {\n",
  "      element.classList.remove(\"collapse\");\n",
  "    });\n"
)
include_post <- sub(clone_line, clone_fix, include_pre, fixed = TRUE)
script_open <- "<script>\n"
script_close <- "</script>\n"
stopifnot(startsWith(include_pre, script_open), endsWith(include_pre, script_close))
script_pre <- substr(
  include_pre,
  nchar(script_open) + 1L,
  nchar(include_pre) - nchar(script_close)
)
script_post <- sub(clone_line, clone_fix, script_pre, fixed = TRUE)

check_live_preimages <- function() {
  live_build <- inventory_files(build_root)
  stopifnot(
    nrow(live_build) == 892L,
    symlink_count(build_root) == 0L,
    same_inventory(baseline, live_build)
  )
  require_file(include_path, include_pre_sha, 1388)
  require_file(source_css_path, css_sha, 4548)
  require_file(build_css_path, css_sha, 4548)
  require_file(corpus_manifest_path, corpus_pre_sha, 11479)
  stopifnot(
    count_fixed(clone_line, include_pre) == 1L,
    nchar(include_post, type = "bytes") == 1542L,
    identical(sha256_text(include_post), include_post_sha),
    identical(sub(clone_fix, clone_line, include_post, fixed = TRUE), include_pre),
    nchar(script_post, type = "bytes") == nchar(script_pre, type = "bytes") + 154L,
    identical(sub(clone_fix, clone_line, script_post, fixed = TRUE), script_pre)
  )
  live_build
}

extract_once <- function(text, pattern, label) {
  matches <- gregexpr(pattern, text, perl = TRUE)[[1L]]
  stopifnot(length(matches) == 1L, matches[[1L]] > 0L)
  regmatches(text, regexpr(pattern, text, perl = TRUE))
}

node_ids <- function(document) {
  values <- xml2::xml_attr(xml2::xml_find_all(document, "//*[@id]"), "id")
  values[!is.na(values) & nzchar(values)]
}

ordered_values <- function(document, xpath, attribute = NULL) {
  nodes <- xml2::xml_find_all(document, xpath)
  if (is.null(attribute)) {
    trimws(xml2::xml_text(nodes))
  } else {
    value <- xml2::xml_attr(nodes, attribute)
    value[!is.na(value)]
  }
}

non_script_dom_sha <- function(text) {
  document <- xml2::read_html(text)
  xml2::xml_remove(xml2::xml_find_all(document, "//script"))
  sha256_text(paste(as.character(document), collapse = ""))
}

visible_text_sha <- function(text) {
  document <- xml2::read_html(text)
  xml2::xml_remove(xml2::xml_find_all(document, "//script|//style|//noscript"))
  body <- xml2::xml_find_first(document, "//body")
  sha256_text(gsub("[[:space:]]+", " ", trimws(xml2::xml_text(body))))
}

idref_audit <- function(document) {
  ids <- node_ids(document)
  attributes <- c(
    "aria-labelledby", "aria-describedby", "aria-controls", "aria-owns",
    "aria-flowto", "aria-activedescendant", "headers", "for", "list", "form"
  )
  rows <- list()
  for (attribute in attributes) {
    nodes <- xml2::xml_find_all(document, paste0("//*[@", attribute, "]"))
    if (!length(nodes)) next
    for (node_index in seq_along(nodes)) {
      value <- xml2::xml_attr(nodes[[node_index]], attribute)
      tokens <- strsplit(trimws(value), "[[:space:]]+")[[1L]]
      tokens <- tokens[nzchar(tokens)]
      for (token in tokens) {
        rows[[length(rows) + 1L]] <- data.frame(
          attribute = attribute,
          token = token,
          matches = sum(ids == token),
          stringsAsFactors = FALSE
        )
      }
    }
  }
  selector_nodes <- xml2::xml_find_all(
    document,
    "//*[@data-bs-target or @data-target]"
  )
  if (length(selector_nodes)) {
    for (node in selector_nodes) {
      for (attribute in c("data-bs-target", "data-target")) {
        value <- xml2::xml_attr(node, attribute)
        if (is.na(value) || !startsWith(value, "#")) next
        token <- substring(value, 2L)
        rows[[length(rows) + 1L]] <- data.frame(
          attribute = attribute,
          token = token,
          matches = sum(ids == token),
          stringsAsFactors = FALSE
        )
      }
    }
  }
  if (!length(rows)) {
    return(data.frame(attribute = character(), token = character(), matches = integer()))
  }
  do.call(rbind, rows)
}

table_header_audit <- function(document) {
  tables <- xml2::xml_find_all(
    document,
    paste0(
      "//table[contains(concat(' ', normalize-space(@class), ' '), ",
      "' gt_table ')]"
    )
  )
  token_count <- 0L
  unresolved <- 0L
  for (table in tables) {
    table_ids <- xml2::xml_attr(
      xml2::xml_find_all(table, "self::*[@id] | .//*[@id]"),
      "id"
    )
    table_ids <- table_ids[!is.na(table_ids) & nzchar(table_ids)]
    values <- xml2::xml_attr(
      xml2::xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
      "headers"
    )
    values <- values[!is.na(values) & nzchar(trimws(values))]
    tokens <- unlist(strsplit(trimws(values), "[[:space:]]+"), use.names = FALSE)
    token_count <- token_count + length(tokens)
    unresolved <- unresolved + sum(vapply(
      tokens,
      function(token) sum(table_ids == token) != 1L,
      logical(1)
    ))
  }
  c(tables = length(tables), tokens = token_count, unresolved = unresolved)
}

resolve_local_target <- function(reference, source_route, root) {
  no_query <- sub("[?].*$", "", reference)
  path_part <- utils::URLdecode(sub("#.*$", "", no_query))
  if (!nzchar(path_part)) return(file.path(root, source_route))
  if (startsWith(path_part, "/")) {
    return(file.path(root, sub("^/+", "", path_part)))
  }
  file.path(dirname(file.path(root, source_route)), path_part)
}

document_cache <- new.env(parent = emptyenv())
cached_ids <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (!exists(normalized, envir = document_cache, inherits = FALSE)) {
    assign(
      normalized,
      node_ids(xml2::read_html(normalized)),
      envir = document_cache
    )
  }
  get(normalized, envir = document_cache, inherits = FALSE)
}

audit_local_links <- function(document, route, root) {
  nodes <- xml2::xml_find_all(document, "//*[@href or @src]")
  references <- ifelse(
    is.na(xml2::xml_attr(nodes, "href")),
    xml2::xml_attr(nodes, "src"),
    xml2::xml_attr(nodes, "href")
  )
  references <- references[!is.na(references) & nzchar(trimws(references))]
  references <- references[!grepl(
    "^(?:[A-Za-z][A-Za-z0-9+.-]*:|//)",
    references,
    perl = TRUE
  )]
  if (!length(references)) {
    return(data.frame(
      route = character(), reference = character(), inside = logical(),
      target_exists = logical(), fragment = character(),
      fragment_resolves = logical(), resolved = logical()
    ))
  }
  normalized_root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  rows <- vector("list", length(references))
  for (index in seq_along(references)) {
    reference <- references[[index]]
    no_query <- sub("[?].*$", "", reference)
    fragment <- if (grepl("#", no_query, fixed = TRUE)) {
      utils::URLdecode(sub("^[^#]*#", "", no_query))
    } else {
      ""
    }
    target <- normalizePath(
      resolve_local_target(reference, route, root),
      winslash = "/",
      mustWork = FALSE
    )
    inside <- identical(target, normalized_root) ||
      startsWith(target, paste0(normalized_root, "/"))
    target_file <- if (dir.exists(target)) file.path(target, "index.html") else target
    exists <- inside && file.exists(target_file)
    fragment_resolves <- TRUE
    if (exists && nzchar(fragment)) {
      if (grepl("\\.html?$", target_file, ignore.case = TRUE)) {
        fragment_resolves <- sum(cached_ids(target_file) == fragment) == 1L
      } else {
        fragment_resolves <- FALSE
      }
    }
    rows[[index]] <- data.frame(
      route = route,
      reference = reference,
      inside = inside,
      target_exists = exists,
      fragment = fragment,
      fragment_resolves = fragment_resolves,
      resolved = inside && exists && fragment_resolves,
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, rows)
}

validate_candidate <- function(write_outputs = TRUE) {
  stopifnot(dir.exists(candidate_build), file.exists(candidate_include))
  candidate_inventory <- inventory_files(candidate_build)
  stopifnot(nrow(candidate_inventory) == 892L, symlink_count(candidate_build) == 0L)

  changed <- baseline$path[
    baseline$sha256 != candidate_inventory$sha256[
      match(baseline$path, candidate_inventory$path)
    ]
  ]
  stopifnot(setequal(changed, routes), length(changed) == 37L)

  transition_rows <- vector("list", length(routes))
  dom_rows <- vector("list", length(routes))
  all_link_rows <- list()
  all_idref_rows <- list()
  all_duplicate_rows <- list()

  for (index in seq_along(routes)) {
    route <- routes[[index]]
    accepted_path <- file.path(build_root, route)
    candidate_path <- file.path(candidate_build, route)
    accepted_text <- read_raw_text(accepted_path)
    candidate_text <- read_raw_text(candidate_path)
    accepted_document <- xml2::read_html(accepted_text)
    candidate_document <- xml2::read_html(candidate_text)

    pre_count <- count_fixed(script_pre, candidate_text)
    post_count <- count_fixed(script_post, candidate_text)
    reversed <- sub(script_post, script_pre, candidate_text, fixed = TRUE)
    transition_rows[[index]] <- data.frame(
      logical_order = manifest_pre$logical_order[[index]],
      source = manifest_pre$source[[index]],
      route = route,
      pre_sha256 = sha256_file(accepted_path),
      post_sha256 = sha256_file(candidate_path),
      pre_bytes = file_bytes(accepted_path),
      post_bytes = file_bytes(candidate_path),
      pre_occurrences_after = pre_count,
      post_occurrences_after = post_count,
      reverse_exact = identical(reversed, accepted_text),
      stringsAsFactors = FALSE
    )

    accepted_ids <- node_ids(accepted_document)
    candidate_ids <- node_ids(candidate_document)
    accepted_id_counts <- table(accepted_ids)
    accepted_duplicate_counts <- accepted_id_counts[accepted_id_counts > 1L]
    candidate_id_counts <- table(candidate_ids)
    candidate_duplicate_counts <- candidate_id_counts[candidate_id_counts > 1L]
    duplicate_multiset_exact <- identical(
      names(accepted_duplicate_counts),
      names(candidate_duplicate_counts)
    ) && identical(
      as.integer(accepted_duplicate_counts),
      as.integer(candidate_duplicate_counts)
    )
    if (length(accepted_duplicate_counts)) {
      all_duplicate_rows[[length(all_duplicate_rows) + 1L]] <- data.frame(
        route = route,
        id = names(accepted_duplicate_counts),
        count = as.integer(accepted_duplicate_counts),
        stringsAsFactors = FALSE
      )
    }
    accepted_idrefs <- idref_audit(accepted_document)
    idrefs <- idref_audit(candidate_document)
    idref_resolution_exact <- identical(accepted_idrefs, idrefs)
    if (nrow(idrefs)) {
      idrefs$route <- route
      all_idref_rows[[length(all_idref_rows) + 1L]] <- idrefs[
        , c("route", "attribute", "token", "matches")
      ]
    }
    accepted_headers <- table_header_audit(accepted_document)
    headers <- table_header_audit(candidate_document)
    header_resolution_exact <- identical(accepted_headers, headers)
    links <- audit_local_links(candidate_document, route, candidate_build)
    if (nrow(links)) all_link_rows[[length(all_link_rows) + 1L]] <- links

    accepted_main <- xml2::xml_find_all(
      accepted_document,
      "//main[@id='quarto-document-content']"
    )
    candidate_main <- xml2::xml_find_all(
      candidate_document,
      "//main[@id='quarto-document-content']"
    )
    accepted_page_nav <- extract_once(
      accepted_text,
      "(?s)<nav class=\"page-navigation[^\"]*\".*?</nav>",
      "accepted page navigation"
    )
    candidate_page_nav <- extract_once(
      candidate_text,
      "(?s)<nav class=\"page-navigation[^\"]*\".*?</nav>",
      "candidate page navigation"
    )

    heading_xpath <- "//main[@id='quarto-document-content']//*[self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6]"
    caption_xpath <- "//main[@id='quarto-document-content']//*[self::figcaption or contains(concat(' ', normalize-space(@class), ' '), ' gt_caption ')]"
    figure_xpath <- "//main[@id='quarto-document-content']//figure//img"
    href_src_xpath <- "//*[@href or @src]"
    accepted_href_src_nodes <- xml2::xml_find_all(accepted_document, href_src_xpath)
    candidate_href_src_nodes <- xml2::xml_find_all(candidate_document, href_src_xpath)
    accepted_href_src <- paste0(
      ifelse(is.na(xml2::xml_attr(accepted_href_src_nodes, "href")), "src=", "href="),
      ifelse(
        is.na(xml2::xml_attr(accepted_href_src_nodes, "href")),
        xml2::xml_attr(accepted_href_src_nodes, "src"),
        xml2::xml_attr(accepted_href_src_nodes, "href")
      )
    )
    candidate_href_src <- paste0(
      ifelse(is.na(xml2::xml_attr(candidate_href_src_nodes, "href")), "src=", "href="),
      ifelse(
        is.na(xml2::xml_attr(candidate_href_src_nodes, "href")),
        xml2::xml_attr(candidate_href_src_nodes, "src"),
        xml2::xml_attr(candidate_href_src_nodes, "href")
      )
    )

    candidate_errors <- xml2::xml_find_all(
      candidate_document,
      paste0(
        "//*[contains(concat(' ', normalize-space(@class), ' '), ",
        "' cell-output-error ') or contains(concat(' ', normalize-space(@class), ",
        "' '), ' quarto-error ')]"
      )
    )

    dom_rows[[index]] <- data.frame(
      route = route,
      desktop_toc_count = length(xml2::xml_find_all(
        candidate_document,
        "//nav[@id='TOC']"
      )),
      mobile_script_count = length(xml2::xml_find_all(
        candidate_document,
        "//script[contains(., 'nathealth-mobile-toc')]"
      )),
      main_count = length(candidate_main),
      id_count = length(candidate_ids),
      duplicate_id_values = length(candidate_duplicate_counts),
      extra_duplicate_instances = sum(candidate_duplicate_counts - 1L),
      duplicate_bearing_nodes = sum(candidate_duplicate_counts),
      duplicate_multiset_exact = duplicate_multiset_exact,
      ids_order_exact = identical(accepted_ids, candidate_ids),
      idref_count = nrow(idrefs),
      unresolved_idrefs = if (nrow(idrefs)) sum(idrefs$matches != 1L) else 0L,
      idref_resolution_exact = idref_resolution_exact,
      gt_tables = headers[["tables"]],
      header_tokens = headers[["tokens"]],
      unresolved_headers = headers[["unresolved"]],
      header_resolution_exact = header_resolution_exact,
      figures = length(xml2::xml_find_all(candidate_document, figure_xpath)),
      element_id_order_exact = identical(
        ordered_values(accepted_document, "//main[@id='quarto-document-content']//*[@id]", "id"),
        ordered_values(candidate_document, "//main[@id='quarto-document-content']//*[@id]", "id")
      ),
      heading_order_exact = identical(
        paste(
          ordered_values(accepted_document, heading_xpath, "id"),
          ordered_values(accepted_document, heading_xpath),
          sep = "|"
        ),
        paste(
          ordered_values(candidate_document, heading_xpath, "id"),
          ordered_values(candidate_document, heading_xpath),
          sep = "|"
        )
      ),
      captions_exact = identical(
        ordered_values(accepted_document, caption_xpath),
        ordered_values(candidate_document, caption_xpath)
      ),
      figure_alt_exact = identical(
        ordered_values(accepted_document, figure_xpath, "alt"),
        ordered_values(candidate_document, figure_xpath, "alt")
      ),
      links_endpoints_exact = identical(accepted_href_src, candidate_href_src),
      page_navigation_exact = identical(accepted_page_nav, candidate_page_nav),
      visible_text_exact = identical(
        visible_text_sha(accepted_text),
        visible_text_sha(candidate_text)
      ),
      non_script_dom_exact = identical(
        non_script_dom_sha(accepted_text),
        non_script_dom_sha(candidate_text)
      ),
      error_nodes = length(candidate_errors),
      stringsAsFactors = FALSE
    )
  }

  transitions <- do.call(rbind, transition_rows)
  dom <- do.call(rbind, dom_rows)
  links <- do.call(rbind, all_link_rows)
  idrefs <- if (length(all_idref_rows)) {
    do.call(rbind, all_idref_rows)
  } else {
    data.frame(route = character(), attribute = character(), token = character(), matches = integer())
  }
  duplicate_multiset <- if (length(all_duplicate_rows)) {
    value <- do.call(rbind, all_duplicate_rows)
    value[order(value$route, value$id), , drop = FALSE]
  } else {
    data.frame(route = character(), id = character(), count = integer())
  }

  stopifnot(
    nrow(transitions) == 37L,
    all(transitions$pre_occurrences_after == 0L),
    all(transitions$post_occurrences_after == 1L),
    all(transitions$post_bytes == transitions$pre_bytes + 154L),
    all(transitions$reverse_exact),
    length(unique(transitions$post_sha256)) == 37L,
    all(dom$desktop_toc_count == 1L),
    all(dom$mobile_script_count == 1L),
    all(dom$main_count == 1L),
    all(dom$duplicate_multiset_exact),
    sum(dom$duplicate_id_values > 0L) == 7L,
    sum(dom$duplicate_id_values) == 63L,
    sum(dom$extra_duplicate_instances) == 149L,
    sum(dom$duplicate_bearing_nodes) == 212L,
    nrow(duplicate_multiset) == 63L,
    all(dom$ids_order_exact),
    all(dom$idref_resolution_exact),
    all(dom$header_resolution_exact),
    all(dom$element_id_order_exact),
    all(dom$heading_order_exact),
    all(dom$captions_exact),
    all(dom$figure_alt_exact),
    all(dom$links_endpoints_exact),
    all(dom$page_navigation_exact),
    all(dom$visible_text_exact),
    all(dom$non_script_dom_exact),
    all(dom$error_nodes == 0L),
    nrow(links) > 10000L,
    all(links$inside),
    all(links$target_exists),
    all(links$fragment_resolves),
    all(links$resolved)
  )

  require_file(candidate_include, include_post_sha, 1542)
  stopifnot(
    identical(
      sub(clone_fix, clone_line, read_raw_text(candidate_include), fixed = TRUE),
      include_pre
    ),
    identical(sha256_file(file.path(candidate_build, "styles-nathealth.css")), css_sha)
  )

  h06_route <- "notebooks/hypotheses/H06.html"
  h06_candidate_path <- file.path(candidate_build, h06_route)
  h06_current_path <- file.path(build_root, h06_route)
  h06_candidate_text <- read_raw_text(h06_candidate_path)
  h06_shell_reversed_text <- sub(
    script_post,
    script_pre,
    h06_candidate_text,
    fixed = TRUE
  )
  stopifnot(identical(h06_shell_reversed_text, read_raw_text(h06_current_path)))
  engine <- new.env(parent = globalenv())
  sys.source(
    file.path(project_root, "scripts/report_harmonization/repair_gt_html_semantics.R"),
    envir = engine
  )
  h06_semantic_dir <- file.path(
    project_root,
    paste0(
      "audit/hypotheses/H06/employment_eligibility_sensitivity/",
      "order66a_result_render"
    )
  )
  semantic_summary <- readr::read_csv(
    file.path(h06_semantic_dir, "gt_html_semantic_post_render_summary.csv"),
    show_col_types = FALSE
  )
  semantic_ledger <- readr::read_csv(
    file.path(h06_semantic_dir, "H06_html_gt_semantic_ledger.csv"),
    show_col_types = FALSE
  )
  stopifnot(
    nrow(semantic_summary) == 1L,
    nrow(semantic_ledger) == 424L,
    semantic_summary$total_substitutions[[1L]] == 424L
  )
  current_semantic_raw <- charToRaw(h06_shell_reversed_text)
  raw_render <- engine$apply_raw_replacements(
    current_semantic_raw,
    semantic_ledger,
    reverse = TRUE
  )
  semantic_reapplied <- engine$apply_raw_replacements(
    raw_render,
    semantic_ledger,
    reverse = FALSE
  )
  shell_reapplied <- sub(
    script_pre,
    script_post,
    rawToChar(semantic_reapplied),
    fixed = TRUE
  )
  h06_reversal <- data.frame(
    check = c(
      "candidate_shell_reverse_to_current",
      "semantic_reverse_to_raw_render",
      "semantic_reapplication_to_current",
      "shell_reapplication_to_candidate"
    ),
    expected_sha256 = c(
      semantic_summary$post_sha256[[1L]],
      semantic_summary$pre_sha256[[1L]],
      semantic_summary$post_sha256[[1L]],
      sha256_file(h06_candidate_path)
    ),
    observed_sha256 = c(
      sha256_text(h06_shell_reversed_text),
      engine$sha256_raw(raw_render),
      engine$sha256_raw(semantic_reapplied),
      sha256_text(shell_reapplied)
    ),
    exact = c(
      identical(h06_shell_reversed_text, read_raw_text(h06_current_path)),
      identical(engine$sha256_raw(raw_render), semantic_summary$pre_sha256[[1L]]),
      identical(semantic_reapplied, current_semantic_raw),
      identical(shell_reapplied, h06_candidate_text)
    ),
    stringsAsFactors = FALSE
  )
  stopifnot(all(h06_reversal$exact))

  manifest_post <- manifest_pre
  manifest_post$html_exists <- TRUE
  manifest_post$html_sha256 <- transitions$post_sha256[
    match(manifest_post$expected_html, file.path("_build/nathealth", transitions$route))
  ]
  stopifnot(!anyNA(manifest_post$html_sha256))
  manifest_post_text <- readr::format_csv(manifest_post)
  stopifnot(
    nchar(manifest_post_text, type = "bytes") == 11479L,
    identical(sha256_text(manifest_post_text), corpus_post_sha),
    identical(manifest_post$source, manifest_pre$source),
    identical(manifest_post$source_sha256, manifest_pre$source_sha256),
    identical(
      manifest_post[names(manifest_post) != "html_sha256"],
      manifest_pre[names(manifest_pre) != "html_sha256"]
    )
  )

  if (write_outputs) {
    readr::write_csv(candidate_inventory, file.path(evidence_dir, "candidate_build_inventory.csv"))
    readr::write_csv(transitions, file.path(evidence_dir, "html_shell_transitions.csv"))
    readr::write_csv(dom, file.path(evidence_dir, "candidate_dom_audit.csv"))
    readr::write_csv(links, file.path(evidence_dir, "candidate_local_link_audit.csv"))
    readr::write_csv(idrefs, file.path(evidence_dir, "candidate_idref_audit.csv"))
    readr::write_csv(
      duplicate_multiset,
      file.path(evidence_dir, "legacy_duplicate_id_multiset.csv")
    )
    readr::write_csv(
      dom[, c(
        "route", "id_count", "duplicate_id_values",
        "extra_duplicate_instances", "duplicate_bearing_nodes",
        "duplicate_multiset_exact", "ids_order_exact"
      )],
      file.path(evidence_dir, "legacy_duplicate_id_route_summary.csv")
    )
    readr::write_csv(h06_reversal, file.path(evidence_dir, "h06_composed_reversal.csv"))
    write_text_atomic(manifest_post_text, file.path(evidence_dir, "prospective_phase4_corpus_manifest.csv"))

    delta <- data.frame(
      path = baseline$path,
      pre_sha256 = baseline$sha256,
      post_sha256 = candidate_inventory$sha256[
        match(baseline$path, candidate_inventory$path)
      ],
      pre_bytes = baseline$bytes,
      post_bytes = candidate_inventory$bytes[
        match(baseline$path, candidate_inventory$path)
      ],
      status = ifelse(baseline$path %in% routes, "AUTHORIZED_HTML_SCRIPT_TRANSITION", "EXACT"),
      stringsAsFactors = FALSE
    )
    readr::write_csv(delta, file.path(evidence_dir, "candidate_build_delta.csv"))

    preexisting_paths <- c(
      "_build/nathealth/notebooks/hypotheses/H01.html",
      "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html",
      "_build/nathealth/notebooks/hypotheses/H06.html"
    )
    preexisting <- data.frame(
      path = preexisting_paths,
      manifest_pre_sha256 = manifest_pre$html_sha256[
        match(preexisting_paths, manifest_pre$expected_html)
      ],
      accepted_live_pre_sha256 = vapply(preexisting_paths, sha256_file, character(1)),
      accepted_live_pre_bytes = vapply(preexisting_paths, file_bytes, numeric(1)),
      status = "ACCEPTED_PREEXISTING_HTML_TRANSITION_BEFORE_ORDER67A",
      stringsAsFactors = FALSE
    )
    stopifnot(
      identical(
        preexisting$manifest_pre_sha256,
        c(
          "eab336d8cde80608968679d68cfc4ed67828c4f60969d51f90d3738b59e63839",
          "52b24d00ed6e5a9251b813932969376e396b6ff89239de9ef413d1a3e9054578",
          "bf3f70118afca9264aba77f9483a1cdd783e3c43996c9049fce67780ceca539b"
        )
      ),
      identical(
        preexisting$accepted_live_pre_sha256,
        c(
          "72458413f3a2b025474abdff556feeb897e4a968a254e2f546565348f8a07e4a",
          "9bb80c068570b168e500da0ce5905859e36543ec2c91aed423c9557aaa33aa0a",
          "b701a6d6e10e37fbe143117b70c0ba78e2d65ade0b973f3e1cd3e43a6f658dc9"
        )
      )
    )
    readr::write_csv(preexisting, file.path(evidence_dir, "preexisting_html_transitions.csv"))
  }

  list(
    inventory = candidate_inventory,
    transitions = transitions,
    dom = dom,
    links = links,
    idrefs = idrefs,
    duplicate_multiset = duplicate_multiset,
    manifest_post_text = manifest_post_text,
    h06_reversal = h06_reversal
  )
}

if (identical(mode, "candidate")) {
  live_build <- check_live_preimages()
  stopifnot(
    !dir.exists(candidate_build),
    length(list.files(candidate_root, all.files = TRUE, no.. = TRUE)) == 0L,
    length(list.files(backup_root, all.files = TRUE, no.. = TRUE)) == 0L
  )

  dir.create(candidate_build, recursive = TRUE, showWarnings = FALSE)
  source_files <- file.path(build_root, live_build$path)
  candidate_files <- file.path(candidate_build, live_build$path)
  invisible(lapply(unique(dirname(candidate_files)), dir.create,
    recursive = TRUE,
    showWarnings = FALSE
  ))
  copied <- mapply(
    file.copy,
    from = source_files,
    to = candidate_files,
    MoreArgs = list(overwrite = FALSE, copy.mode = TRUE),
    SIMPLIFY = TRUE,
    USE.NAMES = FALSE
  )
  stopifnot(all(copied), same_inventory(live_build, inventory_files(candidate_build)))

  write_text_atomic(include_post, candidate_include)
  for (route in routes) {
    path <- file.path(candidate_build, route)
    text <- read_raw_text(path)
    stopifnot(count_fixed(script_pre, text) == 1L, count_fixed(script_post, text) == 0L)
    post <- sub(script_pre, script_post, text, fixed = TRUE)
    stopifnot(
      nchar(post, type = "bytes") == nchar(text, type = "bytes") + 154L,
      identical(sub(script_post, script_pre, post, fixed = TRUE), text)
    )
    write_text_atomic(post, path)
  }

  validation <- validate_candidate(write_outputs = TRUE)
  duplicate_baseline_paths <- file.path(
    evidence_dir,
    c(
      "legacy_duplicate_id_multiset.csv",
      "legacy_duplicate_id_route_summary.csv"
    )
  )
  duplicate_baseline_seal <- data.frame(
    path = substring(duplicate_baseline_paths, nchar(project_root) + 2L),
    sha256 = vapply(duplicate_baseline_paths, sha256_file, character(1)),
    bytes = vapply(duplicate_baseline_paths, file_bytes, numeric(1)),
    rows = c(63L, 37L),
    stringsAsFactors = FALSE
  )
  readr::write_csv(
    duplicate_baseline_seal,
    file.path(evidence_dir, "legacy_duplicate_id_baseline_seal.csv")
  )
  readr::write_csv(live_build, file.path(evidence_dir, "accepted_build_preflight_inventory.csv"))

  protected_paths <- unique(c(
    dispatch$path,
    stop_acceptance_manifest$path,
    fail_manifest$path,
    duplicate_clarification_manifest$path
  ))
  protected_paths <- protected_paths[file.exists(protected_paths) & !dir.exists(protected_paths)]
  protected_inventory <- data.frame(
    path = protected_paths,
    sha256 = vapply(protected_paths, sha256_file, character(1)),
    bytes = vapply(protected_paths, file_bytes, numeric(1)),
    stringsAsFactors = FALSE
  )
  readr::write_csv(
    protected_inventory,
    file.path(evidence_dir, "preflight_protected_inventory.csv")
  )

  promotion_targets <- c(
    "_includes/nathealth-mobile-toc.html",
    file.path("_build/nathealth", routes)
  )
  candidate_paths <- c(candidate_include, file.path(candidate_build, routes))
  promotion_manifest <- data.frame(
    order = seq_along(promotion_targets),
    target_path = promotion_targets,
    candidate_path = candidate_paths,
    pre_sha256 = vapply(promotion_targets, sha256_file, character(1)),
    post_sha256 = vapply(candidate_paths, sha256_file, character(1)),
    pre_bytes = vapply(promotion_targets, file_bytes, numeric(1)),
    post_bytes = vapply(candidate_paths, file_bytes, numeric(1)),
    stringsAsFactors = FALSE
  )
  stopifnot(
    nrow(promotion_manifest) == 38L,
    !anyDuplicated(promotion_manifest$target_path),
    all(promotion_manifest$pre_sha256 != promotion_manifest$post_sha256),
    promotion_manifest$post_sha256[[1L]] == include_post_sha,
    all(promotion_manifest$post_bytes[-1L] == promotion_manifest$pre_bytes[-1L] + 154L)
  )
  promotion_manifest_path <- file.path(evidence_dir, "candidate_promotion_manifest.csv")
  readr::write_csv(promotion_manifest, promotion_manifest_path)
  promotion_seal <- data.frame(
    path = file.path(evidence_rel, "candidate_promotion_manifest.csv"),
    sha256 = sha256_file(promotion_manifest_path),
    bytes = file_bytes(promotion_manifest_path),
    rows = nrow(promotion_manifest),
    stringsAsFactors = FALSE
  )
  readr::write_csv(
    promotion_seal,
    file.path(evidence_dir, "candidate_promotion_manifest_seal.csv")
  )

  checks <- data.frame(
    check = c(
      "dispatch_and_stop_acceptance_exact",
      "accepted_build_exact",
      "candidate_build_bounded",
      "include_postimage_exact",
      "html_transitions_exact_reversible",
      "dom_content_semantics_and_legacy_ids_exact",
      "local_links_and_fragments_resolve",
      "h06_composed_reversal",
      "prospective_manifest_exact",
      "promotion_manifest_presealed",
      "stylesheets_unchanged"
    ),
    status = "PASS",
    detail = c(
      "dispatch 30/30; independent stop acceptance 19/19; owner stop 43/43",
      "892/892 files exact; zero symlinks",
      "892 files; only 37 HTML routes changed",
      paste0(include_post_sha, "; 1542 bytes; exact one-hunk reverse"),
      "37/37 unique; one replacement each; each grows 154 bytes",
      sprintf(
        paste0(
          "routes=37; gt_tables=%d; figures=%d; legacy_duplicate_routes=7; ",
          "duplicate_values=63; extra_instances=149; duplicate_nodes=212; new_id_drift=0; ",
          "idref_and_header_resolution_drift=0"
        ),
        sum(validation$dom$gt_tables),
        sum(validation$dom$figures)
      ),
      sprintf("references=%d; unresolved=0", nrow(validation$links)),
      "shell reverse plus 424 semantic reversals and reapplication exact",
      paste0(corpus_post_sha, "; 11479 bytes; source provenance unchanged"),
      paste0(promotion_seal$sha256[[1L]], "; rows=38"),
      paste0(css_sha, "; source and build exact")
    ),
    stringsAsFactors = FALSE
  )
  readr::write_csv(checks, file.path(evidence_dir, "candidate_static_checks.csv"))
  write_text_atomic(paste0(candidate_root, "\n"), file.path(evidence_dir, "candidate_root.txt"))
  write_text_atomic(paste0(backup_root, "\n"), file.path(evidence_dir, "backup_root.txt"))

  cat(sprintf(
    paste0(
      "ORDER67A_CANDIDATE=PASS build=892/892 routes=37/37 changed=37 ",
      "links=%d tables=%d figures=%d include_post=15396773 ",
      "corpus_post=5d66d43d reverse=38/38 semantic=424 R=%s\n"
    ),
    nrow(validation$links),
    sum(validation$dom$gt_tables),
    sum(validation$dom$figures),
    as.character(getRversion())
  ))
}

validate_browser_rows <- function(path, expected_rows, expected_widths, routes_expected) {
  rows <- jsonlite::fromJSON(path, simplifyDataFrame = TRUE)
  stopifnot(
    is.data.frame(rows),
    nrow(rows) == expected_rows,
    !anyDuplicated(paste(rows$route, rows$viewport_width)),
    setequal(unique(rows$route), routes_expected),
    setequal(unique(rows$viewport_width), expected_widths),
    all(rows$http_ok),
    all(rows$desktop_toc_count == 1L),
    all(rows$mobile_details_count == 1L),
    all(rows$mobile_link_count > 0L),
    all(rows$visible_link_count == rows$mobile_link_count),
    all(rows$focusable_link_count == rows$mobile_link_count),
    all(rows$first_fragment_exists),
    all(rows$disclosure_closed_after_follow),
    all(rows$link_order_matches_desktop),
    all(rows$broken_images == 0L),
    all(rows$console_warnings == 0L),
    all(rows$console_errors == 0L),
    all(!rows$page_overflow),
    all(!rows$clipping_or_overlap),
    all(rows$pass)
  )
  rows
}

validate_desktop_rows <- function(path, routes_expected) {
  rows <- jsonlite::fromJSON(path, simplifyDataFrame = TRUE)
  stopifnot(
    is.data.frame(rows),
    nrow(rows) == length(routes_expected),
    setequal(rows$route, routes_expected),
    !anyDuplicated(rows$route),
    all(rows$viewport_width == 1440L),
    all(rows$viewport_height == 1000L),
    all(rows$http_ok),
    all(rows$mobile_control_hidden),
    all(rows$desktop_toc_visible),
    all(rows$desktop_toc_fixed),
    all(rows$navigation_shell_usable),
    all(rows$broken_images == 0L),
    all(rows$console_warnings == 0L),
    all(rows$console_errors == 0L),
    all(!rows$page_overflow),
    all(rows$pass)
  )
  rows
}

if (identical(mode, "promote")) {
  check_live_preimages()
  validation <- validate_candidate(write_outputs = FALSE)
  stopifnot(!file.exists(file.path(evidence_dir, "promotion_started.txt")))

  duplicate_baseline_seal <- readr::read_csv(
    file.path(evidence_dir, "legacy_duplicate_id_baseline_seal.csv"),
    show_col_types = FALSE
  )
  duplicate_baseline_paths <- file.path(project_root, duplicate_baseline_seal$path)
  stopifnot(
    nrow(duplicate_baseline_seal) == 2L,
    identical(as.integer(duplicate_baseline_seal$rows), c(63L, 37L)),
    all(vapply(duplicate_baseline_paths, sha256_file, character(1)) == duplicate_baseline_seal$sha256),
    all(vapply(duplicate_baseline_paths, file_bytes, numeric(1)) == duplicate_baseline_seal$bytes)
  )

  route_qa <- validate_browser_rows(
    file.path(evidence_dir, "candidate_browser_route_qa.json"),
    74L,
    c(390L, 708L),
    routes
  )
  desktop_qa <- validate_desktop_rows(
    file.path(evidence_dir, "candidate_browser_desktop_qa.json"),
    c("index.html", "notebooks/hypotheses/H06.html", "notebooks/hypotheses/H09.html")
  )
  candidate_lifecycle <- readr::read_csv(
    file.path(evidence_dir, "candidate_server_lifecycle.csv"),
    show_col_types = FALSE
  )
  stopifnot(
    nrow(candidate_lifecycle) == 1L,
    candidate_lifecycle$served_candidate_only[[1L]],
    candidate_lifecycle$pre_serve_symlinks[[1L]] == 0L,
    candidate_lifecycle$server_stopped[[1L]],
    candidate_lifecycle$listener_cleared[[1L]]
  )
  pre_promotion_gate <- readr::read_csv(
    file.path(evidence_dir, "pre_promotion_process_gate.csv"),
    show_col_types = FALSE
  )
  stopifnot(
    nrow(pre_promotion_gate) == 1L,
    identical(pre_promotion_gate$status[[1L]], "PASS"),
    pre_promotion_gate$conflicting_process_count[[1L]] == 0L
  )

  promotion_manifest_path <- file.path(evidence_dir, "candidate_promotion_manifest.csv")
  promotion_seal <- readr::read_csv(
    file.path(evidence_dir, "candidate_promotion_manifest_seal.csv"),
    show_col_types = FALSE
  )
  stopifnot(
    nrow(promotion_seal) == 1L,
    identical(sha256_file(promotion_manifest_path), promotion_seal$sha256[[1L]]),
    file_bytes(promotion_manifest_path) == promotion_seal$bytes[[1L]],
    promotion_seal$rows[[1L]] == 38L
  )
  promotion_manifest <- readr::read_csv(promotion_manifest_path, show_col_types = FALSE)
  stopifnot(nrow(promotion_manifest) == 38L, !anyDuplicated(promotion_manifest$target_path))
  stopifnot(
    all(vapply(promotion_manifest$target_path, sha256_file, character(1)) == promotion_manifest$pre_sha256),
    all(vapply(promotion_manifest$candidate_path, sha256_file, character(1)) == promotion_manifest$post_sha256),
    all(vapply(promotion_manifest$target_path, file_bytes, numeric(1)) == promotion_manifest$pre_bytes),
    all(vapply(promotion_manifest$candidate_path, file_bytes, numeric(1)) == promotion_manifest$post_bytes)
  )

  stopifnot(length(list.files(backup_root, all.files = TRUE, no.. = TRUE)) == 0L)
  backup_files <- file.path(backup_root, "preimages", promotion_manifest$target_path)
  invisible(lapply(unique(dirname(backup_files)), dir.create,
    recursive = TRUE,
    showWarnings = FALSE
  ))
  for (index in seq_len(nrow(promotion_manifest))) {
    copy_file_atomic(promotion_manifest$target_path[[index]], backup_files[[index]])
  }
  corpus_backup <- file.path(
    backup_root,
    "corpus_manifest_preimage",
    "audit/report_harmonization/phase4_corpus_manifest.csv"
  )
  copy_file_atomic(corpus_manifest_path, corpus_backup)
  backup_manifest <- data.frame(
    target_path = promotion_manifest$target_path,
    backup_path = backup_files,
    sha256 = vapply(backup_files, sha256_file, character(1)),
    bytes = vapply(backup_files, file_bytes, numeric(1)),
    stringsAsFactors = FALSE
  )
  stopifnot(
    identical(backup_manifest$sha256, promotion_manifest$pre_sha256),
    identical(backup_manifest$bytes, promotion_manifest$pre_bytes)
  )
  readr::write_csv(backup_manifest, file.path(evidence_dir, "promotion_backup_manifest.csv"))
  write_text_atomic(
    paste0(
      "started_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE), "\n",
      "promotion_manifest_sha256=", sha256_file(promotion_manifest_path), "\n"
    ),
    file.path(evidence_dir, "promotion_started.txt")
  )

  restore_all <- function() {
    for (index in seq_len(nrow(promotion_manifest))) {
      copy_file_atomic(backup_files[[index]], promotion_manifest$target_path[[index]])
    }
    copy_file_atomic(corpus_backup, corpus_manifest_path)
  }

  promotion_ok <- FALSE
  tryCatch({
    for (index in seq_len(nrow(promotion_manifest))) {
      copy_file_atomic(
        promotion_manifest$candidate_path[[index]],
        promotion_manifest$target_path[[index]]
      )
    }
    stopifnot(
      all(vapply(promotion_manifest$target_path, sha256_file, character(1)) == promotion_manifest$post_sha256),
      all(vapply(promotion_manifest$target_path, file_bytes, numeric(1)) == promotion_manifest$post_bytes)
    )
    promoted_build <- inventory_files(build_root)
    stopifnot(nrow(promoted_build) == 892L, symlink_count(build_root) == 0L)
    build_delta <- data.frame(
      path = baseline$path,
      pre_sha256 = baseline$sha256,
      post_sha256 = promoted_build$sha256[match(baseline$path, promoted_build$path)],
      pre_bytes = baseline$bytes,
      post_bytes = promoted_build$bytes[match(baseline$path, promoted_build$path)],
      status = ifelse(baseline$path %in% routes, "AUTHORIZED_HTML_SCRIPT_TRANSITION", "EXACT"),
      stringsAsFactors = FALSE
    )
    stopifnot(
      sum(build_delta$pre_sha256 != build_delta$post_sha256) == 37L,
      setequal(
        build_delta$path[build_delta$pre_sha256 != build_delta$post_sha256],
        routes
      ),
      all(build_delta$pre_sha256[build_delta$status == "EXACT"] ==
        build_delta$post_sha256[build_delta$status == "EXACT"])
    )
    readr::write_csv(
      promoted_build,
      file.path(evidence_dir, "post_promotion_build_inventory.csv")
    )
    readr::write_csv(
      build_delta,
      file.path(evidence_dir, "post_promotion_build_delta.csv")
    )

    write_raw_atomic(read_raw_file(corpus_manifest_path), file.path(evidence_dir, "corpus_manifest_pre.csv"))
    write_text_atomic(validation$manifest_post_text, corpus_manifest_path)
    require_file(corpus_manifest_path, corpus_post_sha, 11479)
    manifest_live <- readr::read_csv(corpus_manifest_path, show_col_types = FALSE)
    stopifnot(
      identical(manifest_live$source, manifest_pre$source),
      identical(manifest_live$source_sha256, manifest_pre$source_sha256),
      identical(
        manifest_live[names(manifest_live) != "html_sha256"],
        manifest_pre[names(manifest_pre) != "html_sha256"]
      ),
      all(manifest_live$html_sha256 == vapply(manifest_live$expected_html, sha256_file, character(1)))
    )

    promotion_execution <- data.frame(
      event = c("promotion", "immediate_build_check", "manifest_reseal"),
      status = "PASS",
      details = c(
        "38 targets promoted once from the sealed candidate",
        "892 files; 37 authorized HTML transitions; 855 exact; zero symlinks",
        paste0("37 HTML hashes updated only; manifest=", corpus_post_sha)
      ),
      stringsAsFactors = FALSE
    )
    readr::write_csv(
      promotion_execution,
      file.path(evidence_dir, "promotion_execution.csv")
    )
    promotion_ok <- TRUE
  }, error = function(error) {
    restore_all()
    write_text_atomic(
      paste0("FAIL_ROLLED_BACK\n", conditionMessage(error), "\n"),
      file.path(evidence_dir, "promotion_failure_rolled_back.txt")
    )
    stop(error)
  })
  stopifnot(promotion_ok)

  cat(sprintf(
    paste0(
      "ORDER67A_PROMOTION=PASS targets=38 html=37 include=1 build=892/892 ",
      "manifest=5d66d43d browser_routes=%d desktop=%d R=%s\n"
    ),
    nrow(route_qa),
    nrow(desktop_qa),
    as.character(getRversion())
  ))
}

if (identical(mode, "postflight")) {
  require_file(include_path, include_post_sha, 1542)
  require_file(source_css_path, css_sha, 4548)
  require_file(build_css_path, css_sha, 4548)
  require_file(corpus_manifest_path, corpus_post_sha, 11479)
  stopifnot(symlink_count(build_root) == 0L)

  duplicate_baseline_seal <- readr::read_csv(
    file.path(evidence_dir, "legacy_duplicate_id_baseline_seal.csv"),
    show_col_types = FALSE
  )
  duplicate_baseline_paths <- file.path(project_root, duplicate_baseline_seal$path)
  stopifnot(
    nrow(duplicate_baseline_seal) == 2L,
    identical(as.integer(duplicate_baseline_seal$rows), c(63L, 37L)),
    all(vapply(duplicate_baseline_paths, sha256_file, character(1)) == duplicate_baseline_seal$sha256),
    all(vapply(duplicate_baseline_paths, file_bytes, numeric(1)) == duplicate_baseline_seal$bytes)
  )

  live_build <- inventory_files(build_root)
  candidate_inventory <- inventory_files(candidate_build)
  stopifnot(
    nrow(live_build) == 892L,
    same_inventory(live_build, candidate_inventory)
  )

  production_route_qa <- validate_browser_rows(
    file.path(evidence_dir, "production_browser_route_qa.json"),
    74L,
    c(390L, 708L),
    routes
  )
  production_desktop_qa <- validate_desktop_rows(
    file.path(evidence_dir, "production_browser_desktop_qa.json"),
    c("index.html", "notebooks/hypotheses/H06.html", "notebooks/hypotheses/H09.html")
  )
  candidate_route_qa <- validate_browser_rows(
    file.path(evidence_dir, "candidate_browser_route_qa.json"),
    74L,
    c(390L, 708L),
    routes
  )
  candidate_desktop_qa <- validate_desktop_rows(
    file.path(evidence_dir, "candidate_browser_desktop_qa.json"),
    c("index.html", "notebooks/hypotheses/H06.html", "notebooks/hypotheses/H09.html")
  )
  h06_qa <- jsonlite::fromJSON(
    file.path(evidence_dir, "production_h06_extended_qa.json"),
    simplifyDataFrame = TRUE
  )
  stopifnot(
    is.data.frame(h06_qa),
    nrow(h06_qa) == 4L,
    setequal(h06_qa$viewport_key, c("1440x1000", "708x1000", "720x500", "figure_642")),
    all(h06_qa$http_ok),
    all(h06_qa$table_count == 14L),
    all(h06_qa$figure_count == 6L),
    all(h06_qa$tables_complete),
    all(h06_qa$figures_complete),
    all(h06_qa$employment_section_complete),
    all(h06_qa$disclosures_usable),
    all(h06_qa$table_scroller_usable),
    all(h06_qa$desktop_or_mobile_toc_usable),
    all(h06_qa$primary_navigation_usable),
    all(h06_qa$reciprocal_preparation_link_ok),
    all(h06_qa$source_data_links_ok),
    all(h06_qa$deviation_links_ok),
    all(h06_qa$figure_width_contract),
    all(h06_qa$linked_routes_http_200),
    all(h06_qa$broken_images == 0L),
    all(h06_qa$console_warnings == 0L),
    all(h06_qa$console_errors == 0L),
    all(!h06_qa$page_overflow),
    all(!h06_qa$clipping_or_overlap),
    all(h06_qa$pass)
  )
  production_lifecycle <- readr::read_csv(
    file.path(evidence_dir, "production_server_lifecycle.csv"),
    show_col_types = FALSE
  )
  stopifnot(
    nrow(production_lifecycle) == 1L,
    production_lifecycle$served_production_only[[1L]],
    production_lifecycle$pre_serve_symlinks[[1L]] == 0L,
    production_lifecycle$server_stopped[[1L]],
    production_lifecycle$listener_cleared[[1L]]
  )

  protected_pre <- readr::read_csv(
    file.path(evidence_dir, "preflight_protected_inventory.csv"),
    show_col_types = FALSE
  )
  protected_post <- protected_pre
  protected_post$sha256_post <- vapply(protected_post$path, sha256_file, character(1))
  protected_post$bytes_post <- vapply(protected_post$path, file_bytes, numeric(1))
  expected_changed_protected <- c(
    "_includes/nathealth-mobile-toc.html",
    "audit/report_harmonization/phase4_corpus_manifest.csv",
    "_build/nathealth/notebooks/hypotheses/H06.html"
  )
  protected_post$status <- ifelse(
    protected_post$path %in% expected_changed_protected,
    "AUTHORIZED_ORDER67A_TRANSITION",
    ifelse(
      protected_post$sha256 == protected_post$sha256_post &
        protected_post$bytes == protected_post$bytes_post,
      "EXACT",
      "UNEXPECTED"
    )
  )
  stopifnot(!any(protected_post$status == "UNEXPECTED"))
  readr::write_csv(
    protected_post,
    file.path(evidence_dir, "postflight_protected_inventory.csv")
  )
  readr::write_csv(
    live_build,
    file.path(evidence_dir, "postflight_build_inventory.csv")
  )

  manifest_historical <- readr::read_csv(
    file.path(evidence_dir, "corpus_manifest_pre.csv"),
    show_col_types = FALSE
  )
  manifest_live <- readr::read_csv(corpus_manifest_path, show_col_types = FALSE)
  stopifnot(
    nrow(manifest_live) == 37L,
    identical(manifest_live$source, manifest_historical$source),
    identical(manifest_live$source_sha256, manifest_historical$source_sha256),
    identical(
      manifest_live[names(manifest_live) != "html_sha256"],
      manifest_historical[names(manifest_historical) != "html_sha256"]
    ),
    all(manifest_live$html_exists),
    all(manifest_live$html_sha256 == vapply(manifest_live$expected_html, sha256_file, character(1)))
  )

  screenshot_paths <- sort(list.files(
    file.path(evidence_dir, "screenshots"),
    pattern = "\\.png$",
    full.names = TRUE
  ))
  stopifnot(length(screenshot_paths) >= 8L, all(file_bytes(screenshot_paths) > 0L))
  screenshot_manifest <- data.frame(
    path = substring(screenshot_paths, nchar(project_root) + 2L),
    sha256 = vapply(screenshot_paths, sha256_file, character(1)),
    bytes = vapply(screenshot_paths, file_bytes, numeric(1)),
    stringsAsFactors = FALSE
  )
  readr::write_csv(
    screenshot_manifest,
    file.path(evidence_dir, "browser_screenshot_manifest.csv")
  )

  combined_browser <- rbind(
    data.frame(
      phase = "candidate_mobile",
      route = candidate_route_qa$route,
      viewport = paste0(candidate_route_qa$viewport_width, "x", candidate_route_qa$viewport_height),
      pass = candidate_route_qa$pass
    ),
    data.frame(
      phase = "candidate_desktop",
      route = candidate_desktop_qa$route,
      viewport = paste0(candidate_desktop_qa$viewport_width, "x", candidate_desktop_qa$viewport_height),
      pass = candidate_desktop_qa$pass
    ),
    data.frame(
      phase = "production_mobile",
      route = production_route_qa$route,
      viewport = paste0(production_route_qa$viewport_width, "x", production_route_qa$viewport_height),
      pass = production_route_qa$pass
    ),
    data.frame(
      phase = "production_desktop",
      route = production_desktop_qa$route,
      viewport = paste0(production_desktop_qa$viewport_width, "x", production_desktop_qa$viewport_height),
      pass = production_desktop_qa$pass
    ),
    data.frame(
      phase = "production_h06_extended",
      route = "notebooks/hypotheses/H06.html",
      viewport = h06_qa$viewport_key,
      pass = h06_qa$pass
    )
  )
  stopifnot(nrow(combined_browser) == 158L, all(combined_browser$pass))
  browser_qa_path <- file.path(evidence_dir, "browser_qa_combined.csv")
  readr::write_csv(combined_browser, browser_qa_path)

  final_checks <- data.frame(
    check = c(
      "include_exact",
      "corpus_manifest_exact_live",
      "build_exact_candidate",
      "protected_boundary",
      "candidate_browser_qa",
      "production_browser_qa",
      "h06_deferred_completion",
      "screenshots",
      "server_teardown",
      "stylesheets_unchanged"
    ),
    status = "PASS",
    detail = c(
      paste0(include_post_sha, "; 1542 bytes"),
      paste0(corpus_post_sha, "; 37/37 HTML live exact; source hashes retained"),
      "892/892 files equal candidate; zero symlinks",
      sprintf("members=%d; unexpected=0", nrow(protected_post)),
      "74 mobile route rows plus 3 desktop route rows pass",
      "74 mobile route rows plus 3 desktop route rows pass",
      "four viewport contracts pass; 14 tables; 6 figures; all required links HTTP 200",
      sprintf("count=%d; all nonempty and sealed", length(screenshot_paths)),
      "candidate and production listeners cleared",
      paste0(css_sha, "; source and build exact")
    ),
    stringsAsFactors = FALSE
  )
  readr::write_csv(final_checks, file.path(evidence_dir, "postflight_checks.csv"))

  h06_path <- file.path(build_root, "notebooks/hypotheses/H06.html")
  transition_path <- file.path(evidence_dir, "html_shell_transitions.csv")
  completion_record_path <- file.path(evidence_dir, "order67a_completion.md")
  record <- paste0(
    "# REPORT-018 Order 67a completion\n\n",
    "Date: 2026-09-02\n\n",
    "Disposition: `PASS_NO_RENDER_SHARED_SHELL_TRANSFORMATION`\n\n",
    "The shared mobile table-of-contents clone now removes Bootstrap collapse state from the detached clone and its cloned descendants. The desktop table of contents is unchanged. The candidate-first transformation updated the shared include and the same embedded script in all 37 reader HTML routes without a Quarto render or any QMD, scientific, stylesheet, visible-content, semantic-table, figure, link, or page-navigation edit.\n\n",
    "The accepted legacy duplicate-ID baseline is preserved byte-for-byte: seven routes, 63 duplicate ID values, 149 extra instances, and 212 duplicate-bearing nodes. No ID was added, removed, renamed, or repaired.\n\n",
    "All 37 routes passed the 708 by 1,000 and 390 by 844 mobile disclosure contract in the isolated candidate and again in production. Index, H06, and H09 passed the 1,440 by 1,000 desktop contract. H06 also completed its deferred 1,440 by 1,000, 708 by 1,000, 720 by 500, and 642-pixel figure-width checks with 14 tables, six figures, the employment-eligibility sensitivity section, navigation, reciprocal preparation link, three source-data links, four deviation links, and linked-route HTTP checks passing.\n\n",
    "The production build retains 892 files and zero symbolic links. Exactly 37 HTML files changed by the authorized 154-byte script substitution. The other 855 build files are byte-identical to the accepted baseline. The shared include is `", sha256_file(include_path), "` (", file_bytes(include_path), " bytes). Both Nature Health stylesheets remain `", css_sha, "` (4,548 bytes).\n\n",
    "The corpus manifest was resealed only for the 37 HTML hashes and is `", sha256_file(corpus_manifest_path), "` (", file_bytes(corpus_manifest_path), " bytes). All 37 historical source paths and source hashes remain unchanged. The H06 HTML is `", sha256_file(h06_path), "` (", file_bytes(h06_path), " bytes).\n\n",
    "Candidate and production servers were stopped, their listeners were cleared, the browser viewport was reset, and the complete post-QA build and protected boundaries remained stable.\n"
  )
  write_text_atomic(record, completion_record_path)

  external_paths <- unique(c(
    order_path,
    dispatch_path,
    stop_acceptance_path,
    stop_acceptance_manifest_path,
    duplicate_clarification_path,
    duplicate_clarification_manifest_path,
    fail_manifest_path,
    dispatch$path,
    stop_acceptance_manifest$path,
    file.path(backup_root, "preimages", readr::read_csv(
      file.path(evidence_dir, "candidate_promotion_manifest.csv"),
      show_col_types = FALSE
    )$target_path),
    file.path(
      backup_root,
      "corpus_manifest_preimage",
      "audit/report_harmonization/phase4_corpus_manifest.csv"
    ),
    include_path,
    corpus_manifest_path,
    h06_path
  ))
  evidence_paths <- sort(list.files(
    evidence_dir,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  ))
  final_manifest_path <- file.path(evidence_dir, "order67a_completion_manifest.csv")
  evidence_paths <- setdiff(evidence_paths, final_manifest_path)
  members <- c(evidence_paths, external_paths)
  members <- members[file.exists(members) & !dir.exists(members)]
  members <- unique(normalizePath(
    members,
    winslash = "/",
    mustWork = TRUE
  ))
  relative_or_absolute <- vapply(members, function(normalized) {
    prefix <- paste0(project_root, "/")
    if (startsWith(normalized, prefix)) substring(normalized, nchar(prefix) + 1L) else normalized
  }, character(1))
  final_manifest <- data.frame(
    path = relative_or_absolute,
    sha256 = vapply(members, sha256_file, character(1)),
    bytes = vapply(members, file_bytes, numeric(1)),
    stringsAsFactors = FALSE
  )
  stopifnot(
    !anyDuplicated(final_manifest$path),
    !file.path(evidence_rel, basename(final_manifest_path)) %in% final_manifest$path
  )
  readr::write_csv(final_manifest, final_manifest_path)
  replay_paths <- ifelse(
    startsWith(final_manifest$path, "/"),
    final_manifest$path,
    file.path(project_root, final_manifest$path)
  )
  stopifnot(
    all(file.exists(replay_paths)),
    identical(
      unname(vapply(replay_paths, sha256_file, character(1))),
      unname(final_manifest$sha256)
    ),
    identical(
      unname(vapply(replay_paths, file_bytes, numeric(1))),
      as.numeric(final_manifest$bytes)
    )
  )

  cat(sprintf(
    paste0(
      "ORDER67A_COMPLETE=PASS routes=37 mobile=148 desktop=6 h06=4 ",
      "build=892/892 symlinks=0 include=%s corpus=%s h06=%s ",
      "record=%s manifest=%s members=%d browser=%s transitions=%s R=%s\n"
    ),
    sha256_file(include_path),
    sha256_file(corpus_manifest_path),
    sha256_file(h06_path),
    sha256_file(completion_record_path),
    sha256_file(final_manifest_path),
    nrow(final_manifest),
    sha256_file(browser_qa_path),
    sha256_file(transition_path),
    as.character(getRversion())
  ))
}
