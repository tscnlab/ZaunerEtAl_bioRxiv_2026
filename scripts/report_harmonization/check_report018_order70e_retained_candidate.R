#!/usr/bin/env Rscript

# Read-only retained-candidate checker for REPORT-018 Order 70e.
# It may write audit evidence only. It never writes candidate or production
# content, sources a QMD, runs Quarto, or calculates a scientific result.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(digest)
  library(jsonlite)
  library(readr)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, args[[1L]] %in% c("candidate", "promote", "postflight"))
mode <- args[[1L]]

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(project_root)

evidence_rel <- paste0(
  "audit/report_harmonization/",
  "nathealth_final_landing_integration_2026_09_02"
)
evidence_dir <- normalizePath(
  Sys.getenv(
    "ORDER70E_CHECK_OUTPUT_DIR",
    unset = file.path(project_root, evidence_rel)
  ),
  winslash = "/",
  mustWork = TRUE
)
stopifnot(dir.exists(evidence_dir))

candidate_root <- normalizePath(
  Sys.getenv("ORDER70_CANDIDATE_ROOT"),
  winslash = "/",
  mustWork = TRUE
)
backup_root <- normalizePath(
  Sys.getenv("ORDER70_BACKUP_ROOT"),
  winslash = "/",
  mustWork = TRUE
)
candidate_build <- file.path(candidate_root, "candidate_build")
build_root <- file.path(project_root, "_build/nathealth")
corpus_path <- file.path(
  project_root,
  "audit/report_harmonization/phase4_corpus_manifest.csv"
)
canonical_html <- file.path(
  project_root,
  "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html"
)
canonical_docx <- file.path(
  project_root,
  "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx"
)
production_index <- file.path(build_root, "index.html")
production_docx <- file.path(
  build_root,
  "ZaunerEtAl2026_NatHealth_phase3_brown.docx"
)

sha_file <- function(path) {
  digest::digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}

sha_raw <- function(value) {
  digest::digest(value, algo = "sha256", serialize = FALSE)
}

sha_text <- function(value) sha_raw(charToRaw(enc2utf8(value)))

bytes_file <- function(path) unname(as.numeric(file.info(path)$size))

read_raw_file <- function(path) {
  size <- bytes_file(path)
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  readBin(con, what = "raw", n = size)
}

read_text <- function(path) rawToChar(read_raw_file(path))

write_raw_atomic <- function(value, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temp <- tempfile(paste0(basename(path), "."), tmpdir = dirname(path))
  con <- file(temp, open = "wb")
  open <- TRUE
  on.exit({
    if (open) close(con)
    if (file.exists(temp)) unlink(temp)
  }, add = TRUE)
  writeBin(value, con)
  close(con)
  open <- FALSE
  if (!file.rename(temp, path)) stop("Atomic replacement failed: ", path)
  invisible(path)
}

write_text_atomic <- function(value, path) {
  write_raw_atomic(charToRaw(enc2utf8(value)), path)
}

copy_atomic <- function(source, target) {
  write_raw_atomic(read_raw_file(source), target)
  stopifnot(identical(sha_file(source), sha_file(target)))
  invisible(target)
}

count_fixed <- function(pattern, text) {
  found <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(found[[1L]], -1L)) return(0L)
  length(found)
}

find_fixed_once <- function(text, token, label = token) {
  found <- gregexpr(token, text, fixed = TRUE)[[1L]]
  if (length(found) != 1L || found[[1L]] < 1L) {
    stop(label, " was not unique")
  }
  unname(found[[1L]])
}

find_after <- function(text, token, after, label = token) {
  tail <- substr(text, after, nchar(text))
  found <- regexpr(token, tail, fixed = TRUE)[[1L]]
  if (found < 1L) stop(label, " was not found after boundary")
  after + found - 1L
}

extract_outer_fixed <- function(text, start_token, close_token, label) {
  start <- find_fixed_once(text, start_token, paste0(label, " start"))
  close_start <- find_after(text, close_token, start + nchar(start_token), paste0(label, " close"))
  substr(text, start, close_start + nchar(close_token) - 1L)
}

extract_inner_fixed <- function(text, open_tag, close_tag, label) {
  start <- find_fixed_once(text, open_tag, paste0(label, " opening tag"))
  close_start <- find_after(text, close_tag, start + nchar(open_tag), paste0(label, " closing tag"))
  substr(text, start + nchar(open_tag), close_start - 1L)
}

replace_once_fixed <- function(text, old, replacement, label = old) {
  stopifnot(count_fixed(old, text) == 1L)
  result <- sub(old, replacement, text, fixed = TRUE)
  stopifnot(!identical(text, result), count_fixed(old, result) == 0L)
  result
}

insert_before_retained_boundary <- function(text, boundary, insertion, label = boundary) {
  stopifnot(count_fixed(boundary, text) == 1L, count_fixed(insertion, text) == 0L)
  result <- sub(boundary, paste0(insertion, boundary), text, fixed = TRUE)
  stopifnot(
    !identical(text, result),
    count_fixed(boundary, result) == 1L,
    count_fixed(insertion, result) == 1L
  )
  result
}

require_file <- function(path, sha256, bytes = NULL) {
  stopifnot(file.exists(path), !dir.exists(path), !nzchar(Sys.readlink(path)))
  stopifnot(identical(sha_file(path), sha256))
  if (!is.null(bytes)) stopifnot(bytes_file(path) == as.numeric(bytes))
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
    sha256 = unname(vapply(members, sha_file, character(1))),
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

write_csv_atomic <- function(value, path) {
  temp <- tempfile(paste0(basename(path), "."), tmpdir = dirname(path))
  readr::write_csv(value, temp, na = "")
  raw <- read_raw_file(temp)
  unlink(temp)
  write_raw_atomic(raw, path)
}

read_exact_manifest <- function(path, expected_rows) {
  manifest <- readr::read_csv(path, show_col_types = FALSE)
  stopifnot(nrow(manifest) == expected_rows, !anyDuplicated(manifest$path))
  stopifnot(!path %in% manifest$path)
  stopifnot(all(file.exists(manifest$path)), !any(dir.exists(manifest$path)))
  observed_sha <- vapply(manifest$path, sha_file, character(1))
  observed_bytes <- unname(as.numeric(file.info(manifest$path)$size))
  stopifnot(
    identical(unname(observed_sha), unname(manifest$sha256)),
    identical(observed_bytes, as.numeric(manifest$bytes))
  )
  manifest
}

script_path <- Sys.getenv(
  "ORDER70E_IMPLEMENTATION_PATH",
  unset = file.path(project_root, evidence_rel, "order70_integrate_verify_promote.R")
)
script_seal_path <- Sys.getenv(
  "ORDER70E_IMPLEMENTATION_SEAL_PATH",
  unset = file.path(project_root, evidence_rel, "implementation_script_seal.csv")
)
script_seal <- readr::read_csv(script_seal_path, show_col_types = FALSE)
stopifnot(
  identical(sha_file(script_path), "345837702576f0ed5ddfbd01dd484820e5edb0ae730acb786168ecd1c9cc7ed8"),
  bytes_file(script_path) == 53259,
  nrow(script_seal) == 1L,
  identical(
    script_seal$path[[1L]],
    file.path(evidence_rel, "order70_integrate_verify_promote.R")
  ),
  identical(script_seal$sha256[[1L]], sha_file(script_path)),
  script_seal$bytes[[1L]] == bytes_file(script_path)
)

script_text <- read_text(script_path)
idref_postimage <- paste0(
  "    nrow(idrefs) == 2776L,\n",
  "    sum(idrefs$attribute == \"aria-labelledby\") == 6L,\n",
  "    sum(idrefs$attribute == \"aria-describedby\") == 6L,\n",
  "    sum(idrefs$attribute == \"aria-controls\") == 1L,\n",
  "    sum(idrefs$attribute == \"headers\") == 2762L,\n",
  "    sum(idrefs$attribute == \"data-bs-target\") == 1L,\n",
  "    sum(idrefs$attribute == \"data-target\") == 0L,"
)
idref_preimage <- "    nrow(idrefs) == 2775L,"
order70d_text <- replace_once_fixed(
  script_text,
  idref_postimage,
  idref_preimage,
  "IDREF-cardinality reverse proof"
)
stopifnot(
  identical(
    sha_raw(charToRaw(enc2utf8(order70d_text))),
    "86a9131c715b4ee18b2e5790c5a1e3ea68dec35da0716a9de90635aeb412b8bc"
  ),
  length(charToRaw(enc2utf8(order70d_text))) == 52946L
)

dispatch_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_navigation_order70_dispatch_manifest.csv"
)
order70a_manifest_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_navigation_order70a_dispatch_manifest.csv"
)
order70b_manifest_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_navigation_order70b_dispatch_manifest.csv"
)
require_file(
  dispatch_path,
  "69fc086da4f5890f3b4d15245b83f8d76ac36489311d6600d20e137025351e0d",
  3505
)
require_file(
  order70a_manifest_path,
  "cfe626d776c2471f0864de040c2f2e4e8013884c675fe8b2a4a4c35831f13cee",
  2520
)
require_file(
  order70b_manifest_path,
  "60989e0c36438564c83abe8b7b0912f13e75be2587b6eae3695732d661002b8f",
  2719
)

if (mode %in% c("candidate", "promote")) {
  dispatch <- read_exact_manifest(dispatch_path, 19L)
  order70a_dispatch <- read_exact_manifest(order70a_manifest_path, 12L)
  order70b_dispatch <- read_exact_manifest(order70b_manifest_path, 13L)
} else {
  dispatch <- readr::read_csv(dispatch_path, show_col_types = FALSE)
  order70a_dispatch <- readr::read_csv(order70a_manifest_path, show_col_types = FALSE)
  order70b_dispatch <- readr::read_csv(order70b_manifest_path, show_col_types = FALSE)
  stopifnot(
    nrow(dispatch) == 19L,
    nrow(order70a_dispatch) == 12L,
    nrow(order70b_dispatch) == 13L,
    !anyDuplicated(dispatch$path),
    !anyDuplicated(order70a_dispatch$path),
    !anyDuplicated(order70b_dispatch$path)
  )
}

accepted_inventory_path <- file.path(
  project_root,
  paste0(
    "audit/report_harmonization/navigation_mobile_toc_collapse_repair_2026_09_02/",
    "order67a_clone_state_repair/post_promotion_build_inventory.csv"
  )
)
require_file(
  accepted_inventory_path,
  "a45ec438ae36fcba8ae420d6824e342f8822cce182f9351e41e624ed4ae8a5c5",
  124510
)
accepted_inventory <- readr::read_csv(accepted_inventory_path, show_col_types = FALSE)
accepted_inventory <- accepted_inventory[order(accepted_inventory$path), c("path", "sha256", "bytes")]
rownames(accepted_inventory) <- NULL
stopifnot(nrow(accepted_inventory) == 892L, !anyDuplicated(accepted_inventory$path))

legacy_dom_path <- file.path(
  project_root,
  paste0(
    "audit/report_harmonization/navigation_mobile_toc_collapse_repair_2026_09_02/",
    "order67a_clone_state_repair/candidate_dom_audit.csv"
  )
)
legacy_duplicate_multiset_path <- file.path(
  project_root,
  paste0(
    "audit/report_harmonization/navigation_mobile_toc_collapse_repair_2026_09_02/",
    "order67a_clone_state_repair/legacy_duplicate_id_multiset.csv"
  )
)
legacy_duplicate_summary_path <- file.path(
  project_root,
  paste0(
    "audit/report_harmonization/navigation_mobile_toc_collapse_repair_2026_09_02/",
    "order67a_clone_state_repair/legacy_duplicate_id_route_summary.csv"
  )
)
legacy_browser_path <- file.path(
  project_root,
  paste0(
    "audit/report_harmonization/navigation_mobile_toc_collapse_repair_2026_09_02/",
    "order67a_clone_state_repair/production_browser_route_qa.json"
  )
)
require_file(legacy_dom_path, "3ebf810429b74ae7e547ead63f7ce7c6b453954947762cdc03902c8c0c47372c", 5590)
require_file(legacy_duplicate_multiset_path, "551b4e54b340963ac5b8cb55265874d94eab0f2fd2f24629e8f99576a99d5b8f", 3265)
require_file(legacy_duplicate_summary_path, "8f28de29231c6afb529363744887f0683a6b0e3404281c15ae56e99f6a2bfb97", 2415)
require_file(legacy_browser_path, "9571ee93bebb87baa1f6a9ed73ea2041c170f5aced434bb64ff601a3c0fe3720", 75495)

corpus_pre_sha <- "5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b"
index_pre_sha <- "600b7a3d5eb244e99e841b5c4e3b6c1c7440004303fe0e9da1bc0c874add1184"
canonical_html_sha <- "8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac"
canonical_docx_sha <- "6cd592391f720829ed278a35e81c854ee7fd54eca6a4a4e664faad7b37310f91"
brown_svg_sha <- "200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653"

manifest_source <- if (identical(mode, "postflight")) {
  file.path(evidence_dir, "corpus_manifest_pre.csv")
} else {
  corpus_path
}
manifest_pre <- readr::read_csv(manifest_source, show_col_types = FALSE)
stopifnot(
  nrow(manifest_pre) == 37L,
  !anyDuplicated(manifest_pre$source),
  !anyDuplicated(manifest_pre$expected_html)
)
routes <- sub("^_build/nathealth/", "", manifest_pre$expected_html)
stopifnot(length(routes) == 37L, identical(routes[[1L]], "index.html"))

check_prebuild <- function() {
  require_file(corpus_path, corpus_pre_sha, 11479)
  require_file(production_index, index_pre_sha, 405444)
  stopifnot(!file.exists(production_docx))
  live <- inventory_files(build_root)
  stopifnot(nrow(live) == 892L, symlink_count(build_root) == 0L)
  stopifnot(same_inventory(accepted_inventory, live))
  live
}

copy_tree_exact <- function(source, target) {
  stopifnot(dir.exists(source), !file.exists(target), !dir.exists(target))
  dir.create(target, recursive = TRUE, showWarnings = FALSE)
  directories <- sort(list.dirs(source, recursive = TRUE, full.names = TRUE))
  directories <- directories[directories != normalizePath(source, winslash = "/")]
  if (length(directories)) {
    relative <- substring(directories, nchar(normalizePath(source, winslash = "/")) + 2L)
    for (path in file.path(target, relative)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  files <- sort(list.files(
    source,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  ))
  stopifnot(!any(nzchar(Sys.readlink(files))))
  relative <- substring(files, nchar(normalizePath(source, winslash = "/")) + 2L)
  for (index in seq_along(files)) copy_atomic(files[[index]], file.path(target, relative[[index]]))
  invisible(target)
}

build_candidate_index <- function(site_text, manuscript_text) {
  site_main_open <- '<main class="content column-body" id="quarto-document-content">'
  manuscript_main_open <- '<main class="content page-columns page-full" id="quarto-document-content">'
  manuscript_main_inner <- extract_inner_fixed(
    manuscript_text,
    manuscript_main_open,
    "</main>",
    "accepted manuscript main"
  )
  site_main_inner <- extract_inner_fixed(
    site_text,
    site_main_open,
    "</main>",
    "accepted site main"
  )
  result <- replace_once_fixed(site_text, site_main_inner, manuscript_main_inner, "landing main")

  site_meta_start <- find_fixed_once(site_text, '<meta name="author"', "site author metadata")
  site_meta_end <- find_after(site_text, "</title>", site_meta_start, "site title close") + nchar("</title>") - 1L
  site_meta <- substr(site_text, site_meta_start, site_meta_end)
  manuscript_meta_positions <- gregexpr('<meta name="author"', manuscript_text, fixed = TRUE)[[1L]]
  stopifnot(length(manuscript_meta_positions) == 28L, all(manuscript_meta_positions > 0L))
  manuscript_meta_start <- unname(manuscript_meta_positions[[1L]])
  manuscript_meta_end <- find_after(manuscript_text, "</title>", manuscript_meta_start, "manuscript title close") + nchar("</title>") - 1L
  manuscript_meta <- substr(manuscript_text, manuscript_meta_start, manuscript_meta_end)
  result <- replace_once_fixed(result, site_meta, manuscript_meta, "page metadata")

  site_toc <- extract_outer_fixed(site_text, '<nav id="TOC"', "</nav>", "site TOC")
  manuscript_toc <- extract_outer_fixed(manuscript_text, '<nav id="TOC"', "</nav>", "manuscript TOC")
  site_toc_open_end <- find_after(site_toc, ">", 1L, "site TOC opening end")
  site_toc_open <- substr(site_toc, 1L, site_toc_open_end)
  manuscript_toc_open_end <- find_after(manuscript_toc, ">", 1L, "manuscript TOC opening end")
  manuscript_toc_open <- substr(manuscript_toc, 1L, manuscript_toc_open_end)
  toc_actions <- extract_outer_fixed(site_toc, '<div class="toc-actions">', "</div>", "site TOC actions")
  new_toc <- replace_once_fixed(manuscript_toc, manuscript_toc_open, site_toc_open, "TOC opening")
  new_toc <- replace_once_fixed(
    new_toc,
    '<h2 id="toc-title">Table of contents</h2>',
    '<h2 id="toc-title">On this page</h2>',
    "TOC title"
  )
  new_toc <- insert_before_retained_boundary(new_toc, "</nav>", toc_actions, "TOC actions insertion")
  result <- replace_once_fixed(result, site_toc, new_toc, "page TOC")

  custom_style <- extract_outer_fixed(
    manuscript_text,
    '<style type="text/css">div.manuscript-table,',
    "</style>",
    "manuscript-specific style"
  )
  stopifnot(count_fixed(custom_style, site_text) == 0L)
  result <- insert_before_retained_boundary(result, "</head>", paste0(custom_style, "\n"), "manuscript style insertion")

  modal_start <- find_fixed_once(
    result,
    '<div class="modal fade" id="quarto-embedded-source-code-modal"',
    "legacy source modal"
  )
  content_close <- find_after(result, "</div> <!-- /content -->", modal_start, "content close")
  result <- paste0(substr(result, 1L, modal_start - 1L), substr(result, content_close, nchar(result)))

  list(
    text = result,
    manuscript_main_inner = manuscript_main_inner,
    manuscript_meta = manuscript_meta,
    custom_style = custom_style,
    site_header = extract_outer_fixed(site_text, '<header id="quarto-header"', "</header>", "site header"),
    site_footer = extract_outer_fixed(site_text, '<footer class="footer">', "</footer>", "site footer"),
    site_page_navigation = extract_outer_fixed(site_text, '<nav class="page-navigation column-body">', "</nav>", "site page navigation"),
    toc_actions = toc_actions
  )
}

node_ids <- function(document) {
  values <- xml2::xml_attr(xml2::xml_find_all(document, "//*[@id]"), "id")
  values[!is.na(values) & nzchar(values)]
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
    for (node in nodes) {
      value <- xml2::xml_attr(node, attribute)
      tokens <- unlist(strsplit(trimws(value), "[[:space:]]+"), use.names = FALSE)
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
  selector_nodes <- xml2::xml_find_all(document, "//*[@data-bs-target or @data-target]")
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
  if (!length(rows)) {
    return(data.frame(attribute = character(), token = character(), matches = integer()))
  }
  do.call(rbind, rows)
}

table_header_audit <- function(document) {
  tables <- xml2::xml_find_all(
    document,
    "//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
  )
  token_count <- 0L
  unresolved <- 0L
  for (table in tables) {
    table_ids <- xml2::xml_attr(xml2::xml_find_all(table, "self::*[@id] | .//*[@id]"), "id")
    table_ids <- table_ids[!is.na(table_ids) & nzchar(table_ids)]
    values <- xml2::xml_attr(xml2::xml_find_all(table, "self::*[@headers] | .//*[@headers]"), "headers")
    values <- values[!is.na(values) & nzchar(trimws(values))]
    tokens <- unlist(strsplit(trimws(values), "[[:space:]]+"), use.names = FALSE)
    token_count <- token_count + length(tokens)
    unresolved <- unresolved + sum(vapply(tokens, function(token) sum(table_ids == token) != 1L, logical(1)))
  }
  c(tables = length(tables), tokens = token_count, unresolved = unresolved)
}

document_cache <- new.env(parent = emptyenv())
cached_ids <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (!exists(normalized, envir = document_cache, inherits = FALSE)) {
    assign(normalized, node_ids(xml2::read_html(normalized)), envir = document_cache)
  }
  get(normalized, envir = document_cache, inherits = FALSE)
}

resolve_target <- function(reference, route, root) {
  no_query <- sub("[?].*$", "", reference)
  path_part <- utils::URLdecode(sub("#.*$", "", no_query))
  if (!nzchar(path_part)) return(file.path(root, route))
  if (startsWith(path_part, "/")) return(file.path(root, sub("^/+", "", path_part)))
  file.path(dirname(file.path(root, route)), path_part)
}

audit_local_links <- function(document, route, root) {
  nodes <- xml2::xml_find_all(document, "//*[@href or @src]")
  references <- ifelse(
    is.na(xml2::xml_attr(nodes, "href")),
    xml2::xml_attr(nodes, "src"),
    xml2::xml_attr(nodes, "href")
  )
  references <- references[!is.na(references) & nzchar(trimws(references))]
  references <- references[!grepl("^(?:[A-Za-z][A-Za-z0-9+.-]*:|//)", references, perl = TRUE)]
  if (!length(references)) {
    return(data.frame(route = character(), reference = character(), resolved = logical()))
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
    target <- normalizePath(resolve_target(reference, route, root), winslash = "/", mustWork = FALSE)
    inside <- identical(target, normalized_root) || startsWith(target, paste0(normalized_root, "/"))
    target_file <- if (dir.exists(target)) file.path(target, "index.html") else target
    exists <- inside && file.exists(target_file)
    fragment_matches <- NA_integer_
    fragment_resolves <- TRUE
    if (exists && nzchar(fragment)) {
      fragment_matches <- if (grepl("[.]html?$", target_file, ignore.case = TRUE)) {
        sum(cached_ids(target_file) == fragment)
      } else {
        0L
      }
      fragment_resolves <- fragment_matches >= 1L
    }
    rows[[index]] <- data.frame(
      route = route,
      reference = reference,
      target = target_file,
      inside = inside,
      target_exists = exists,
      fragment = fragment,
      fragment_matches = fragment_matches,
      resolved = inside && exists && fragment_resolves,
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, rows)
}

expected_table_ids <- c(
  "tbl-participant-site-manuscript",
  "tbl-plan-brown-main-adherence",
  "tbl-plan-h01-metric-synthesis-candidate",
  "tbl-plan-descriptive-sample-flow",
  "tbl-near-eye-metrics",
  "tbl-recommendation-context",
  "tbl-plan-brown-cross-window-associations",
  "tbl-plan-h02-glasses-variation-shapley-gt-candidate",
  "tbl-plan-h02-chest-variation-shapley-gt-candidate",
  "tbl-h01-primary-publication-summary",
  "tbl-h07-near-results",
  "tbl-h06-primary-effects",
  "tbl-plan-person-level-synthesis-gt-candidate",
  "tbl-h05-near-results-a",
  "tbl-h05-near-results-b",
  "tbl-h08-near-eye-results",
  "tbl-h09-near-eye-results",
  "tbl-h10-main-results",
  "tbl-h11-global-tests"
)
expected_figure_ids <- c(
  "fig-study-overview", "fig-daily-architecture", "fig-activity-context",
  paste0("fig-s", 1:17)
)

validate_landing <- function(candidate_path, accepted_site_path, write_outputs = TRUE) {
  site_text <- read_text(accepted_site_path)
  manuscript_text <- read_text(canonical_html)
  candidate_text <- read_text(candidate_path)
  transform <- build_candidate_index(site_text, manuscript_text)
  stopifnot(identical(candidate_text, transform$text))
  stopifnot(!grepl("/Users/zauner/", candidate_text, fixed = TRUE))
  stopifnot(count_fixed('id="quarto-embedded-source-code-modal"', candidate_text) == 0L)
  stopifnot(count_fixed(transform$custom_style, candidate_text) == 1L)
  stopifnot(count_fixed(transform$site_header, candidate_text) == 1L)
  stopifnot(count_fixed(transform$site_footer, candidate_text) == 1L)
  stopifnot(count_fixed(transform$site_page_navigation, candidate_text) == 1L)
  stopifnot(count_fixed(transform$toc_actions, candidate_text) == 1L)
  stopifnot(count_fixed(transform$manuscript_main_inner, candidate_text) == 1L)
  stopifnot(count_fixed(transform$manuscript_meta, candidate_text) == 1L)

  candidate_document <- xml2::read_html(candidate_text)
  manuscript_document <- xml2::read_html(manuscript_text)
  site_document <- xml2::read_html(site_text)
  ids <- node_ids(candidate_document)
  duplicate_table <- table(ids)
  duplicate_values <- names(duplicate_table)[duplicate_table > 1L]
  idrefs <- idref_audit(candidate_document)
  headers <- table_header_audit(candidate_document)
  stopifnot(
    length(xml2::xml_find_all(candidate_document, "//main")) == 1L,
    length(xml2::xml_find_all(candidate_document, "//nav[@id='TOC']")) == 1L,
    length(duplicate_values) == 0L,
    nrow(idrefs) == 2776L,
    sum(idrefs$attribute == "aria-labelledby") == 6L,
    sum(idrefs$attribute == "aria-describedby") == 6L,
    sum(idrefs$attribute == "aria-controls") == 1L,
    sum(idrefs$attribute == "headers") == 2762L,
    sum(idrefs$attribute == "data-bs-target") == 1L,
    sum(idrefs$attribute == "data-target") == 0L,
    sum(idrefs$matches != 1L) == 0L,
    headers[["tables"]] == 19L,
    headers[["tokens"]] == 2762L,
    headers[["unresolved"]] == 0L
  )

  authors_meta <- xml2::xml_attr(xml2::xml_find_all(candidate_document, "//meta[@name='author']"), "content")
  authors_body <- trimws(xml2::xml_text(xml2::xml_find_all(candidate_document, "//main//p[contains(concat(' ',normalize-space(@class),' '),' author ')]")))
  source_authors_meta <- xml2::xml_attr(xml2::xml_find_all(manuscript_document, "//meta[@name='author']"), "content")
  source_authors_body <- trimws(xml2::xml_text(xml2::xml_find_all(manuscript_document, "//main//p[contains(concat(' ',normalize-space(@class),' '),' author ')]")))
  stopifnot(
    length(authors_meta) == 28L,
    length(authors_body) == 28L,
    identical(authors_meta, source_authors_meta),
    identical(authors_body, source_authors_body)
  )

  for (id in expected_table_ids) {
    node <- xml2::xml_find_all(candidate_document, paste0("//*[@id='", id, "']"))
    stopifnot(length(node) == 1L)
    table_count <- length(xml2::xml_find_all(node, "self::table[contains(concat(' ',normalize-space(@class),' '),' gt_table ')] | .//table[contains(concat(' ',normalize-space(@class),' '),' gt_table ')]"))
    stopifnot(table_count == 1L)
  }
  for (id in expected_figure_ids) {
    node <- xml2::xml_find_all(candidate_document, paste0("//*[@id='", id, "']"))
    stopifnot(length(node) == 1L)
    images <- xml2::xml_find_all(node, ".//img")
    captions <- xml2::xml_find_all(node, ".//figcaption")
    stopifnot(length(images) == 1L, length(captions) == 1L)
    stopifnot(nzchar(trimws(xml2::xml_attr(images, "alt"))))
    stopifnot(nzchar(trimws(xml2::xml_text(captions))))
  }

  main <- xml2::xml_find_first(candidate_document, "//main")
  manuscript_main <- xml2::xml_find_first(manuscript_document, "//main")
  fragment_links <- xml2::xml_attr(xml2::xml_find_all(main, ".//a[starts-with(@href, '#')]"), "href")
  stopifnot(length(fragment_links) == 124L)
  fragment_tokens <- utils::URLdecode(sub("^#", "", fragment_links))
  stopifnot(all(vapply(fragment_tokens, function(token) sum(ids == token) == 1L, logical(1))))

  images <- xml2::xml_find_all(main, ".//img")
  image_src <- xml2::xml_attr(images, "src")
  stopifnot(length(images) == 74L, all(grepl("^data:image/[^,]+;base64,", image_src)))
  decoded <- lapply(image_src, function(value) jsonlite::base64_dec(sub("^[^,]+,", "", value)))
  stopifnot(all(vapply(decoded, length, integer(1)) > 0L))
  brown_image <- xml2::xml_find_all(candidate_document, "//*[@id='fig-s6']//img")
  stopifnot(length(brown_image) == 1L)
  brown_src <- xml2::xml_attr(brown_image, "src")
  stopifnot(startsWith(brown_src, "data:image/svg+xml;base64,"))
  brown_raw <- jsonlite::base64_dec(sub("^[^,]+,", "", brown_src))
  stopifnot(length(brown_raw) == 108600L, identical(sha_raw(brown_raw), brown_svg_sha))

  stopifnot(length(xml2::xml_find_all(candidate_document, "//*[@id='tbl-metric-context']//img[contains(concat(' ',normalize-space(@class),' '),' metric-density-thumb ')]")) == 17L)
  stopifnot(length(xml2::xml_find_all(candidate_document, "//*[@id='fig-s8']//img")) == 1L)
  stopifnot(length(xml2::xml_find_all(candidate_document, "//*[@id='fig-s12']//img")) == 1L)

  doc_links <- xml2::xml_attr(xml2::xml_find_all(candidate_document, "//a[contains(translate(@href,'DOCX','docx'),'.docx')]"), "href")
  doc_labels <- trimws(xml2::xml_text(xml2::xml_find_all(candidate_document, "//a[contains(translate(@href,'DOCX','docx'),'.docx')]")))
  stopifnot(
    length(doc_links) == 1L,
    identical(doc_links[[1L]], "ZaunerEtAl2026_NatHealth_phase3_brown.docx"),
    identical(doc_labels[[1L]], "MS Word")
  )
  stopifnot(length(xml2::xml_find_all(candidate_document, "//nav[@id='TOC']//a")) == 42L)
  stopifnot(length(xml2::xml_find_all(candidate_document, "//nav[@id='TOC']//a[starts-with(@href,'#')]")) == 39L)
  stopifnot(identical(trimws(xml2::xml_text(xml2::xml_find_first(candidate_document, "//nav[@id='TOC']/h2"))), "On this page"))

  candidate_scripts <- vapply(xml2::xml_find_all(candidate_document, "//script"), as.character, character(1))
  site_scripts <- vapply(xml2::xml_find_all(site_document, "//script"), as.character, character(1))
  stopifnot(length(candidate_scripts) == 20L, identical(candidate_scripts, site_scripts))

  source_children <- xml2::xml_children(manuscript_main)
  candidate_children <- xml2::xml_children(main)
  stopifnot(length(source_children) == length(candidate_children))
  ledger <- data.frame(
    position = seq_along(source_children),
    node_name = vapply(source_children, xml2::xml_name, character(1)),
    id = vapply(source_children, function(node) {
      value <- xml2::xml_attr(node, "id")
      ifelse(is.na(value), "", value)
    }, character(1)),
    source_sha256 = vapply(source_children, function(node) sha_text(as.character(node)), character(1)),
    candidate_sha256 = vapply(candidate_children, function(node) sha_text(as.character(node)), character(1)),
    exact = vapply(seq_along(source_children), function(index) identical(as.character(source_children[[index]]), as.character(candidate_children[[index]])), logical(1)),
    stringsAsFactors = FALSE
  )
  stopifnot(all(ledger$exact), identical(ledger$source_sha256, ledger$candidate_sha256))

  summary <- data.frame(
    metric = c(
      "authors_meta", "authors_body", "gt_tables", "table_header_tokens",
      "unresolved_table_headers", "figure_endpoints", "embedded_images",
      "main_internal_fragments", "unresolved_idrefs", "duplicate_id_values",
      "brown_svg_bytes", "brown_svg_sha256_exact", "docx_links", "toc_links",
      "script_count", "main_inner_raw_sha256"
    ),
    observed = c(
      length(authors_meta), length(authors_body), headers[["tables"]],
      headers[["tokens"]], headers[["unresolved"]], length(expected_figure_ids),
      length(images), length(fragment_links), sum(idrefs$matches != 1L),
      length(duplicate_values), length(brown_raw), identical(sha_raw(brown_raw), brown_svg_sha),
      length(doc_links), length(xml2::xml_find_all(candidate_document, "//nav[@id='TOC']//a")),
      length(candidate_scripts), sha_text(transform$manuscript_main_inner)
    ),
    expected = c(
      28, 28, 19, 2762, 0, 20, 74, 124, 0, 0, 108600, TRUE, 1, 42, 20,
      sha_text(transform$manuscript_main_inner)
    ),
    pass = TRUE,
    stringsAsFactors = FALSE
  )
  if (write_outputs) {
    write_csv_atomic(ledger, file.path(evidence_dir, paste0(mode, "_manuscript_element_ledger.csv")))
    write_csv_atomic(summary, file.path(evidence_dir, paste0(mode, "_landing_preservation_summary.csv")))
  }
  list(summary = summary, document = candidate_document, transform = transform)
}

validate_build <- function(root, accepted_site_path, label, write_outputs = TRUE) {
  candidate_inventory <- inventory_files(root)
  stopifnot(nrow(candidate_inventory) == 893L, symlink_count(root) == 0L)
  stopifnot(file.exists(file.path(root, "ZaunerEtAl2026_NatHealth_phase3_brown.docx")))
  require_file(file.path(root, "ZaunerEtAl2026_NatHealth_phase3_brown.docx"), canonical_docx_sha, 28792333)

  aligned <- merge(
    accepted_inventory,
    candidate_inventory,
    by = "path",
    all = TRUE,
    suffixes = c("_accepted", "_candidate")
  )
  aligned$classification <- ifelse(
    is.na(aligned$sha256_accepted),
    "ADDED",
    ifelse(aligned$sha256_accepted == aligned$sha256_candidate, "EXACT", "CHANGED")
  )
  changed <- aligned$path[aligned$classification == "CHANGED"]
  added <- aligned$path[aligned$classification == "ADDED"]
  removed <- aligned$path[is.na(aligned$sha256_candidate)]
  stopifnot(
    identical(changed, "index.html"),
    identical(added, "ZaunerEtAl2026_NatHealth_phase3_brown.docx"),
    length(removed) == 0L,
    sum(aligned$classification == "EXACT") == 891L
  )
  for (route in routes[-1L]) {
    stopifnot(identical(sha_file(file.path(root, route)), sha_file(file.path(build_root, route))))
  }

  landing <- validate_landing(file.path(root, "index.html"), accepted_site_path, write_outputs)
  legacy_dom <- readr::read_csv(legacy_dom_path, show_col_types = FALSE)
  stopifnot(nrow(legacy_dom) == 37L, setequal(legacy_dom$route, routes))
  legacy_non_index <- legacy_dom[legacy_dom$route != "index.html", ]
  stopifnot(
    sum(legacy_non_index$duplicate_id_values) == 63L,
    sum(legacy_non_index$extra_duplicate_instances) == 149L,
    sum(legacy_non_index$duplicate_bearing_nodes) == 212L,
    sum(legacy_non_index$unresolved_idrefs) == 7298L,
    sum(legacy_non_index$unresolved_headers) == 5509L
  )

  dom_rows <- vector("list", length(routes))
  link_rows <- list()
  for (index in seq_along(routes)) {
    route <- routes[[index]]
    path <- file.path(root, route)
    text <- read_text(path)
    document <- xml2::read_html(text)
    ids <- node_ids(document)
    counts <- table(ids)
    idrefs <- idref_audit(document)
    headers <- table_header_audit(document)
    baseline <- legacy_dom[legacy_dom$route == route, ]
    classification <- if (identical(route, "index.html")) {
      "CLEAN_NEW_LANDING_PAGE"
    } else {
      "ACCEPTED_LEGACY_BASELINE_PRESERVED"
    }
    if (!identical(route, "index.html")) {
      stopifnot(
        length(baseline$route) == 1L,
        length(ids) == baseline$id_count,
        sum(counts > 1L) == baseline$duplicate_id_values,
        sum(pmax(as.integer(counts) - 1L, 0L)) == baseline$extra_duplicate_instances,
        sum(as.integer(counts)[counts > 1L]) == baseline$duplicate_bearing_nodes,
        nrow(idrefs) == baseline$idref_count,
        sum(idrefs$matches != 1L) == baseline$unresolved_idrefs,
        headers[["tables"]] == baseline$gt_tables,
        headers[["tokens"]] == baseline$header_tokens,
        headers[["unresolved"]] == baseline$unresolved_headers
      )
    } else {
      stopifnot(sum(counts > 1L) == 0L, sum(idrefs$matches != 1L) == 0L, headers[["unresolved"]] == 0L)
    }
    dom_rows[[index]] <- data.frame(
      route = route,
      main_count = length(xml2::xml_find_all(document, "//main")),
      desktop_toc_count = length(xml2::xml_find_all(document, "//nav[@id='TOC']")),
      id_count = length(ids),
      duplicate_id_values = sum(counts > 1L),
      extra_duplicate_instances = sum(pmax(as.integer(counts) - 1L, 0L)),
      idref_count = nrow(idrefs),
      unresolved_idrefs = sum(idrefs$matches != 1L),
      gt_tables = headers[["tables"]],
      header_tokens = headers[["tokens"]],
      unresolved_headers = headers[["unresolved"]],
      error_nodes = length(xml2::xml_find_all(document, "//*[contains(@class,'cell-output-error') or contains(@class,'error')][not(self::code)]")),
      classification = classification,
      pass = TRUE,
      stringsAsFactors = FALSE
    )
    link_rows[[index]] <- audit_local_links(document, route, root)
    rm(document)
    gc(FALSE)
  }
  dom <- do.call(rbind, dom_rows)
  links <- do.call(rbind, link_rows)
  stopifnot(all(dom$main_count == 1L), all(dom$desktop_toc_count == 1L), all(links$resolved))

  if (write_outputs) {
    write_csv_atomic(candidate_inventory, file.path(evidence_dir, paste0(label, "_build_inventory.csv")))
    write_csv_atomic(aligned, file.path(evidence_dir, paste0(label, "_build_delta.csv")))
    write_csv_atomic(dom, file.path(evidence_dir, paste0(label, "_dom_audit.csv")))
    write_csv_atomic(links, file.path(evidence_dir, paste0(label, "_local_reference_audit.csv")))
    protected <- data.frame(
      route = routes[-1L],
      accepted_sha256 = vapply(file.path(build_root, routes[-1L]), sha_file, character(1)),
      candidate_sha256 = vapply(file.path(root, routes[-1L]), sha_file, character(1)),
      exact = TRUE,
      stringsAsFactors = FALSE
    )
    write_csv_atomic(protected, file.path(evidence_dir, paste0(label, "_protected_36_routes.csv")))
  }
  list(inventory = candidate_inventory, delta = aligned, dom = dom, links = links, landing = landing)
}

validate_browser_evidence <- function(prefix) {
  route_path <- file.path(evidence_dir, paste0(prefix, "_browser_route_qa.json"))
  landing_path <- file.path(evidence_dir, paste0(prefix, "_browser_landing_qa.json"))
  lifecycle_path <- file.path(evidence_dir, paste0(prefix, "_server_lifecycle.csv"))
  screenshot_path <- file.path(evidence_dir, paste0(prefix, "_screenshot_manifest.csv"))
  stopifnot(file.exists(route_path), file.exists(landing_path), file.exists(lifecycle_path), file.exists(screenshot_path))
  route_qa <- jsonlite::fromJSON(route_path, simplifyDataFrame = TRUE)
  landing_qa <- jsonlite::fromJSON(landing_path, simplifyDataFrame = TRUE)
  lifecycle <- readr::read_csv(lifecycle_path, show_col_types = FALSE)
  screenshots <- readr::read_csv(screenshot_path, show_col_types = FALSE)
  stopifnot(
    nrow(route_qa) == 74L,
    setequal(route_qa$route, routes),
    setequal(unique(route_qa$viewport_width), c(390L, 708L)),
    all(route_qa$pass),
    sum(route_qa$classification == "CLEAN_NEW_LANDING_PAGE") == 2L,
    sum(route_qa$classification == "ACCEPTED_LEGACY_OVERFLOW_BASELINE_PRESERVED") == 1L,
    sum(route_qa$classification == "CLEAN_UNCHANGED_ROUTE") == 71L,
    nrow(landing_qa) == 3L,
    setequal(landing_qa$viewport_width, c(390L, 708L, 1440L)),
    all(landing_qa$pass),
    all(!landing_qa$page_overflow),
    any(lifecycle$event == "listener_absent" & lifecycle$pass),
    nrow(screenshots) >= 8L,
    all(file.exists(screenshots$path)),
    all(vapply(screenshots$path, sha_file, character(1)) == screenshots$sha256),
    all(as.numeric(file.info(screenshots$path)$size) == screenshots$bytes)
  )
  invisible(TRUE)
}

run_candidate <- function() {
  candidate_root_members <- sort(list.files(
    candidate_root,
    all.files = TRUE,
    no.. = TRUE
  ))
  stopifnot(
    identical(candidate_root_members, "candidate_build"),
    dir.exists(candidate_build)
  )
  retained_candidate <- inventory_files(candidate_build)
  stopifnot(
    nrow(retained_candidate) == 892L,
    symlink_count(candidate_build) == 0L,
    same_inventory(accepted_inventory, retained_candidate)
  )
  live <- check_prebuild()
  write_csv_atomic(live, file.path(evidence_dir, "accepted_build_preflight_inventory.csv"))
  write_raw_atomic(read_raw_file(corpus_path), file.path(evidence_dir, "corpus_manifest_pre.csv"))
  protected <- dispatch
  protected$observed_sha256 <- vapply(protected$path, sha_file, character(1))
  protected$observed_bytes <- unname(as.numeric(file.info(protected$path)$size))
  protected$exact <- protected$sha256 == protected$observed_sha256 & protected$bytes == protected$observed_bytes
  stopifnot(all(protected$exact))
  write_csv_atomic(protected, file.path(evidence_dir, "dispatch_preflight_reproduction.csv"))

  transform <- build_candidate_index(read_text(production_index), read_text(canonical_html))
  write_text_atomic(transform$text, file.path(candidate_build, "index.html"))
  copy_atomic(canonical_docx, file.path(candidate_build, basename(production_docx)))

  validated <- validate_build(candidate_build, production_index, "candidate", TRUE)
  transition <- data.frame(
    path = "index.html",
    accepted_sha256 = index_pre_sha,
    candidate_sha256 = sha_file(file.path(candidate_build, "index.html")),
    accepted_bytes = 405444,
    candidate_bytes = bytes_file(file.path(candidate_build, "index.html")),
    classification = "APPROVED_LANDING_REPLACEMENT",
    stringsAsFactors = FALSE
  )
  addition <- data.frame(
    path = basename(production_docx),
    candidate_sha256 = sha_file(file.path(candidate_build, basename(production_docx))),
    candidate_bytes = bytes_file(file.path(candidate_build, basename(production_docx))),
    classification = "APPROVED_FINAL_DOCX_ADDITION",
    stringsAsFactors = FALSE
  )
  promotion <- data.frame(
    source = c(
      file.path(candidate_build, "index.html"),
      file.path(candidate_build, basename(production_docx))
    ),
    target = c(production_index, production_docx),
    sha256 = c(transition$candidate_sha256, addition$candidate_sha256),
    bytes = c(transition$candidate_bytes, addition$candidate_bytes),
    action = c("REPLACE_ONCE", "ADD_ONCE"),
    stringsAsFactors = FALSE
  )
  checks <- data.frame(
    check = c(
      "dispatch_19_of_19", "accepted_build_892", "candidate_build_893",
      "zero_symlinks", "other_891_exact", "other_36_routes_exact",
      "new_landing_clean_dom", "authors_28", "gt_tables_19",
      "figures_20", "header_tokens_2762", "fragments_124",
      "brown_svg_exact", "docx_exact", "local_references_resolve",
      "no_render_invoked"
    ),
    pass = TRUE,
    detail = c(
      "19/19", "892/892", "893", "0", "891", "36", "0 duplicates and 0 unresolved IDREF/header tokens",
      "28", "19", "20", "2762", "124", brown_svg_sha, canonical_docx_sha,
      paste0(sum(validated$links$resolved), "/", nrow(validated$links)), "program contains no render command")
    , stringsAsFactors = FALSE)
  write_csv_atomic(transition, file.path(evidence_dir, "candidate_landing_transition.csv"))
  write_csv_atomic(addition, file.path(evidence_dir, "candidate_docx_addition.csv"))
  write_csv_atomic(promotion, file.path(evidence_dir, "candidate_promotion_manifest.csv"))
  write_csv_atomic(checks, file.path(evidence_dir, "candidate_static_checks.csv"))
  cat(
    paste0(
      "ORDER70_CANDIDATE=PASS index_sha256=", transition$candidate_sha256,
      " bytes=", transition$candidate_bytes,
      " files=", nrow(validated$inventory),
      " links=", nrow(validated$links), "\n"
    )
  )
}

run_promote <- function() {
  stopifnot(!file.exists(file.path(evidence_dir, "promotion_started.txt")))
  check_prebuild()
  validated <- validate_build(candidate_build, production_index, "candidate_pre_promotion", TRUE)
  validate_browser_evidence("candidate")
  process_gate_path <- file.path(evidence_dir, "pre_promotion_process_gate.csv")
  process_gate <- readr::read_csv(process_gate_path, show_col_types = FALSE)
  stopifnot(nrow(process_gate) == 1L, process_gate$status[[1L]] == "PASS", process_gate$conflicting_process_count[[1L]] == 0L)
  promotion <- readr::read_csv(file.path(evidence_dir, "candidate_promotion_manifest.csv"), show_col_types = FALSE)
  stopifnot(nrow(promotion) == 2L, !anyDuplicated(promotion$target))
  stopifnot(all(vapply(promotion$source, sha_file, character(1)) == promotion$sha256))
  stopifnot(all(as.numeric(file.info(promotion$source)$size) == promotion$bytes))

  stopifnot(length(list.files(backup_root, all.files = TRUE, no.. = TRUE)) == 0L)
  dir.create(file.path(backup_root, "preimages"), recursive = TRUE, showWarnings = FALSE)
  backup_index <- file.path(backup_root, "preimages/index.html")
  backup_corpus <- file.path(backup_root, "preimages/phase4_corpus_manifest.csv")
  copy_atomic(production_index, backup_index)
  copy_atomic(corpus_path, backup_corpus)
  backup_manifest <- data.frame(
    path = c(backup_index, backup_corpus),
    source_path = c(production_index, corpus_path),
    sha256 = c(sha_file(backup_index), sha_file(backup_corpus)),
    bytes = c(bytes_file(backup_index), bytes_file(backup_corpus)),
    recoverable = TRUE,
    stringsAsFactors = FALSE
  )
  write_csv_atomic(backup_manifest, file.path(evidence_dir, "promotion_backup_manifest.csv"))
  write_text_atomic(
    paste0(format(Sys.time(), tz = "UTC", usetz = TRUE), "\n"),
    file.path(evidence_dir, "promotion_started.txt")
  )

  promoted <- FALSE
  failure <- NULL
  tryCatch({
    copy_atomic(file.path(candidate_build, "index.html"), production_index)
    copy_atomic(file.path(candidate_build, basename(production_docx)), production_docx)
    new_index_sha <- sha_file(production_index)
    corpus_raw <- read_raw_file(backup_corpus)
    corpus_text <- rawToChar(corpus_raw)
    stopifnot(count_fixed(index_pre_sha, corpus_text) == 1L)
    corpus_new <- sub(index_pre_sha, new_index_sha, corpus_text, fixed = TRUE)
    stopifnot(identical(sub(new_index_sha, index_pre_sha, corpus_new, fixed = TRUE), corpus_text))
    write_text_atomic(corpus_new, corpus_path)
    promoted <- TRUE
  }, error = function(error) {
    failure <<- conditionMessage(error)
  })
  if (!promoted) {
    copy_atomic(backup_index, production_index)
    if (file.exists(production_docx)) unlink(production_docx)
    copy_atomic(backup_corpus, corpus_path)
    stop("Promotion rolled back: ", failure)
  }

  production <- validate_build(build_root, backup_index, "production_prebrowser", TRUE)
  stopifnot(same_inventory(production$inventory, validated$inventory))
  corpus <- readr::read_csv(corpus_path, show_col_types = FALSE)
  stopifnot(nrow(corpus) == 37L, !anyDuplicated(corpus$source), !anyDuplicated(corpus$expected_html))
  stopifnot(identical(corpus$source_sha256, manifest_pre$source_sha256))
  preserved_columns <- setdiff(names(corpus), "html_sha256")
  stopifnot(identical(corpus[, preserved_columns], manifest_pre[, preserved_columns]))
  live_hashes <- vapply(corpus$expected_html, sha_file, character(1))
  stopifnot(identical(unname(live_hashes), unname(corpus$html_sha256)))
  changed_rows <- which(corpus$html_sha256 != manifest_pre$html_sha256)
  stopifnot(identical(changed_rows, 1L))
  manifest_transition <- data.frame(
    logical_order = corpus$logical_order,
    source = corpus$source,
    expected_html = corpus$expected_html,
    old_html_sha256 = manifest_pre$html_sha256,
    new_html_sha256 = corpus$html_sha256,
    changed = seq_len(nrow(corpus)) == 1L,
    live_exact = live_hashes == corpus$html_sha256,
    stringsAsFactors = FALSE
  )
  write_csv_atomic(manifest_transition, file.path(evidence_dir, "corpus_manifest_reseal_transition.csv"))
  write_csv_atomic(production$inventory, file.path(evidence_dir, "post_promotion_build_inventory.csv"))
  execution <- data.frame(
    timestamp_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    promotion_count = 1L,
    files_promoted = 2L,
    landing_sha256 = sha_file(production_index),
    docx_sha256 = sha_file(production_docx),
    corpus_manifest_sha256 = sha_file(corpus_path),
    build_files = nrow(production$inventory),
    build_symlinks = symlink_count(build_root),
    rollback_required = FALSE,
    pass = TRUE,
    stringsAsFactors = FALSE
  )
  write_csv_atomic(execution, file.path(evidence_dir, "promotion_execution.csv"))
  cat(
    paste0(
      "ORDER70_PROMOTION=PASS index_sha256=", sha_file(production_index),
      " docx_sha256=", sha_file(production_docx),
      " manifest_sha256=", sha_file(corpus_path), "\n"
    )
  )
}

run_postflight <- function() {
  stopifnot(file.exists(file.path(evidence_dir, "promotion_started.txt")))
  backup_index <- file.path(backup_root, "preimages/index.html")
  backup_corpus <- file.path(backup_root, "preimages/phase4_corpus_manifest.csv")
  require_file(backup_index, index_pre_sha, 405444)
  require_file(backup_corpus, corpus_pre_sha, 11479)
  candidate <- validate_build(candidate_build, backup_index, "candidate_postflight", TRUE)
  production <- validate_build(build_root, backup_index, "production_final", TRUE)
  stopifnot(same_inventory(candidate$inventory, production$inventory))
  validate_browser_evidence("candidate")
  validate_browser_evidence("production")

  corpus <- readr::read_csv(corpus_path, show_col_types = FALSE)
  pre <- readr::read_csv(backup_corpus, show_col_types = FALSE)
  stopifnot(nrow(corpus) == 37L, identical(corpus$source_sha256, pre$source_sha256))
  preserved_columns <- setdiff(names(corpus), "html_sha256")
  stopifnot(identical(corpus[, preserved_columns], pre[, preserved_columns]))
  stopifnot(identical(which(corpus$html_sha256 != pre$html_sha256), 1L))
  live_hashes <- vapply(corpus$expected_html, sha_file, character(1))
  stopifnot(identical(unname(live_hashes), unname(corpus$html_sha256)))

  immutable_dispatch <- dispatch[!dispatch$path %in% c(
    "audit/report_harmonization/phase4_corpus_manifest.csv",
    "_build/nathealth/index.html"
  ), ]
  stopifnot(all(vapply(immutable_dispatch$path, sha_file, character(1)) == immutable_dispatch$sha256))
  stopifnot(all(as.numeric(file.info(immutable_dispatch$path)$size) == immutable_dispatch$bytes))

  checks <- data.frame(
    check = c(
      "candidate_production_893_exact", "build_symlinks_zero", "other_891_exact",
      "protected_36_routes_exact", "landing_clean_dom", "authors_28",
      "tables_19", "figures_20", "header_tokens_2762", "fragments_124",
      "brown_svg_exact", "docx_exact", "local_references_resolve",
      "candidate_browser_74", "production_browser_74", "landing_browser_3x2",
      "corpus_rows_37", "corpus_source_provenance_preserved",
      "corpus_html_live_37", "single_manifest_html_transition",
      "single_promotion", "no_render_invoked"
    ),
    pass = TRUE,
    detail = c(
      "893/893", "0", "891", "36", "0 duplicates and 0 unresolved IDREF/header tokens",
      "28", "19", "20", "2762", "124", brown_svg_sha, canonical_docx_sha,
      paste0(sum(production$links$resolved), "/", nrow(production$links)), "74/74", "74/74",
      "3 candidate plus 3 production", "37", "37/37", "37/37", "index only", "1", "program contains no render command"
    ),
    stringsAsFactors = FALSE
  )
  write_csv_atomic(checks, file.path(evidence_dir, "postflight_checks.csv"))

  completion_path <- file.path(evidence_dir, "order70_completion.md")
  completion <- paste0(
    "# REPORT-018 Order 70 completion\n\n",
    "Date: 2026-09-02\n\n",
    "Status: `PASS`\n\n",
    "The accepted final Nature Health manuscript is integrated into the manuscript landing page on `rewrite/NH` without running Quarto or scientific code. The accepted site navbar, search, footer, route sequence, right-hand desktop TOC, and collapsed mobile TOC remain in place.\n\n",
    "The production build contains 893 regular files and zero symlinks. Relative to the accepted 892-file build, only `index.html` changed and the exact corrected Word file was added. The other 891 files, including all other 36 HTML routes, remain byte-identical.\n\n",
    "The landing page preserves 28 authors, 19 native semantic tables, 20 figure endpoints, 2,762 resolving table-header tokens, 124 resolving manuscript fragment links, 74 embedded images, and the exact accepted Brown SVG. The new landing page has no duplicate IDs or unresolved IDREF/header tokens.\n\n",
    "Candidate and production browser QA passed all 37 routes at 708 and 390 pixels, plus the complete landing page at 1,440, 708, and 390 pixels. The sole accepted legacy overflow classification remains the unchanged Descriptives route at 708 pixels. Both bounded servers were stopped and their listeners were verified absent.\n\n",
    "The 37-row corpus manifest retains all historical source identities and updates only the landing HTML hash.\n"
  )
  write_text_atomic(completion, completion_path)

  all_evidence <- sort(list.files(evidence_dir, recursive = TRUE, full.names = TRUE, all.files = TRUE, include.dirs = FALSE, no.. = TRUE))
  completion_manifest_path <- file.path(evidence_dir, "order70_completion_manifest.csv")
  all_evidence <- setdiff(all_evidence, completion_manifest_path)
  completion_manifest <- data.frame(
    path = substring(all_evidence, nchar(project_root) + 2L),
    sha256 = vapply(all_evidence, sha_file, character(1)),
    bytes = unname(as.numeric(file.info(all_evidence)$size)),
    stringsAsFactors = FALSE
  )
  stopifnot(!anyDuplicated(completion_manifest$path), !completion_manifest_path %in% completion_manifest$path)
  write_csv_atomic(completion_manifest, completion_manifest_path)
  replay <- readr::read_csv(completion_manifest_path, show_col_types = FALSE)
  stopifnot(
    nrow(replay) == nrow(completion_manifest),
    identical(vapply(replay$path, sha_file, character(1)), replay$sha256),
    identical(as.numeric(file.info(replay$path)$size), as.numeric(replay$bytes))
  )
  cat(
    paste0(
      "ORDER70_POSTFLIGHT=PASS index_sha256=", sha_file(production_index),
      " docx_sha256=", sha_file(production_docx),
      " corpus_sha256=", sha_file(corpus_path),
      " evidence_manifest_sha256=", sha_file(completion_manifest_path), "\n"
    )
  )
}

stopifnot(
  identical(sha_file(file.path(candidate_build, "index.html")), "c8abe2f9fbfcbe2fc8b4e39e149797a6dc2d74a5735337ed2399fb6e5814eb21"),
  identical(sha_file(production_index), index_pre_sha),
  identical(sha_file(corpus_path), corpus_pre_sha),
  !file.exists(production_docx),
  identical(sort(list.files(candidate_root, all.files = TRUE, no.. = TRUE)), "candidate_build"),
  length(list.files(backup_root, all.files = TRUE, no.. = TRUE)) == 0L
)

validated_readonly <- validate_build(
  candidate_build,
  production_index,
  "candidate",
  TRUE
)
transition <- data.frame(
  path = "index.html",
  accepted_sha256 = index_pre_sha,
  candidate_sha256 = sha_file(file.path(candidate_build, "index.html")),
  accepted_bytes = 405444,
  candidate_bytes = bytes_file(file.path(candidate_build, "index.html")),
  classification = "APPROVED_LANDING_REPLACEMENT",
  stringsAsFactors = FALSE
)
addition <- data.frame(
  path = basename(production_docx),
  candidate_sha256 = sha_file(file.path(candidate_build, basename(production_docx))),
  candidate_bytes = bytes_file(file.path(candidate_build, basename(production_docx))),
  classification = "APPROVED_FINAL_DOCX_ADDITION",
  stringsAsFactors = FALSE
)
promotion <- data.frame(
  source = c(
    file.path(candidate_build, "index.html"),
    file.path(candidate_build, basename(production_docx))
  ),
  target = c(production_index, production_docx),
  sha256 = c(transition$candidate_sha256, addition$candidate_sha256),
  bytes = c(transition$candidate_bytes, addition$candidate_bytes),
  action = c("REPLACE_ONCE", "ADD_ONCE"),
  stringsAsFactors = FALSE
)
checks <- data.frame(
  check = c(
    "retained_candidate_build_893", "zero_symlinks", "other_891_exact",
    "other_36_routes_exact", "new_landing_clean_dom", "idrefs_2776_exact",
    "idrefs_attribute_breakdown_exact", "idrefs_unresolved_zero",
    "authors_28", "gt_tables_19", "figures_20", "header_tokens_2762",
    "fragments_124", "brown_svg_exact", "docx_exact",
    "local_references_resolve", "no_candidate_transform", "no_render_invoked"
  ),
  pass = TRUE,
  detail = c(
    "893", "0", "891", "36", "0 duplicate IDs and 0 unresolved IDREF/header tokens",
    "2776", "aria-labelledby=6; aria-describedby=6; aria-controls=1; headers=2762; data-bs-target=1; data-target=0",
    "0", "28", "19", "20", "2762", "124", brown_svg_sha,
    canonical_docx_sha, paste0(sum(validated_readonly$links$resolved), "/", nrow(validated_readonly$links)),
    "retained candidate inspected without regeneration", "checker contains no invoked render path"
  ),
  stringsAsFactors = FALSE
)
hard_pin_audit <- data.frame(
  item = c(
    "implementation_postimage_and_sidecar",
    "order70d_implementation_preimage",
    "retained_candidate_index",
    "retained_candidate_docx",
    "production_landing_preimage",
    "production_corpus_preimage",
    "production_docx_absence",
    "promotion_manifest_generation",
    "completion_manifest_self_exclusion",
    "checker_candidate_write_path",
    "checker_production_write_path",
    "checker_self_pin"
  ),
  classification = c(
    "EXACT_FINAL_IDENTITY",
    "REVERSE_PROOF_PRESERVED",
    "EXACT_POST_TRANSFORM_CANDIDATE",
    "EXACT_ACCEPTED_COPY",
    "EXACT_UNCHANGED_PREIMAGE",
    "EXACT_UNCHANGED_PREIMAGE",
    "EXACT_ABSENT_PREIMAGE",
    "EVIDENCE_ONLY_PRESEAL",
    "SAFE_NON_CIRCULAR_EXCLUSION_PRESENT",
    "NONE_INVOKED",
    "NONE_INVOKED",
    "SAFE_NO_SELF_PIN"
  ),
  pass = TRUE,
  stringsAsFactors = FALSE
)
write_csv_atomic(transition, file.path(evidence_dir, "candidate_landing_transition.csv"))
write_csv_atomic(addition, file.path(evidence_dir, "candidate_docx_addition.csv"))
write_csv_atomic(promotion, file.path(evidence_dir, "candidate_promotion_manifest.csv"))
write_csv_atomic(checks, file.path(evidence_dir, "candidate_static_checks.csv"))
write_csv_atomic(
  hard_pin_audit,
  file.path(evidence_dir, "order70e_retained_candidate_hard_pin_audit.csv")
)
cat(
  "ORDER70E_RETAINED_CANDIDATE=PASS files=",
  nrow(validated_readonly$inventory),
  " links=",
  nrow(validated_readonly$links),
  " idrefs=2776 hard_pins=",
  nrow(hard_pin_audit),
  "\n",
  sep = ""
)
