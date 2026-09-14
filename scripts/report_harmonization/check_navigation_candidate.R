#!/usr/bin/env Rscript

# Read-only candidate gate for the bounded no-rerender navigation integration.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(jsonlite)
  library(openssl)
  library(readr)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))
arguments <- commandArgs(trailingOnly = TRUE)
phase <- if (length(arguments)) arguments[[1L]] else "final"
stopifnot(phase %in% c("prebrowser", "final"))

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(project_root)
source(
  file.path(
    project_root,
    "scripts/report_harmonization/navigation_integration_support.R"
  ),
  local = TRUE
)

evidence_dir <- file.path(project_root, nav_integration_evidence_rel)
candidate_root <- trimws(nav_read_text(file.path(evidence_dir, "candidate_root.txt")))
candidate_root <- normalizePath(candidate_root, winslash = "/", mustWork = TRUE)
candidate_build <- file.path(candidate_root, "candidate_build")
stopifnot(dir.exists(candidate_build), !any(nzchar(Sys.readlink(candidate_build))))

manifest <- readr::read_csv(
  "audit/report_harmonization/phase4_corpus_manifest.csv",
  show_col_types = FALSE
)
routes <- vapply(manifest$expected_html, nav_html_route, character(1))
stopifnot(nrow(manifest) == 37L, !anyDuplicated(routes))
transitions <- readr::read_csv(
  file.path(evidence_dir, "candidate_html_transitions.csv"),
  show_col_types = FALSE
)
layout_class_exempt_routes <- c(
  "index.html",
  "notebooks/hypotheses/H06_daily.html",
  "notebooks/hypotheses/H07.html"
)
layout_routes <- setdiff(routes, layout_class_exempt_routes)

checks <- list()
add_check <- function(check_id, pass, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check_id = check_id,
    pass = isTRUE(pass),
    detail = as.character(detail),
    stringsAsFactors = FALSE
  )
}

pre_inventory <- readr::read_csv(
  file.path(evidence_dir, "build_inventory_pre.csv"),
  show_col_types = FALSE
)
live_accepted_inventory <- nav_inventory_tree(file.path(project_root, "_build/nathealth"))
add_check(
  "accepted_build_still_sealed",
  nav_inventories_identical(pre_inventory, live_accepted_inventory),
  sprintf("members=%d unchanged=TRUE", nrow(live_accepted_inventory))
)

candidate_inventory <- nav_inventory_tree(candidate_build)
readr::write_csv(
  candidate_inventory,
  file.path(evidence_dir, "candidate_build_inventory.csv")
)
pre_paths <- pre_inventory$path
candidate_paths <- candidate_inventory$path
added <- setdiff(candidate_paths, pre_paths)
removed <- setdiff(pre_paths, candidate_paths)
common <- intersect(pre_paths, candidate_paths)
changed <- common[vapply(common, function(path) {
  pre <- pre_inventory[pre_inventory$path == path, , drop = FALSE]
  post <- candidate_inventory[candidate_inventory$path == path, , drop = FALSE]
  !nav_inventories_identical(pre, post)
}, logical(1))]
expected_changed <- routes
expected_added <- names(nav_candidate_asset_hashes)
delta <- data.frame(
  disposition = c(
    rep("added", length(added)),
    rep("removed", length(removed)),
    rep("changed", length(changed))
  ),
  path = c(added, removed, changed),
  stringsAsFactors = FALSE
)
readr::write_csv(delta, file.path(evidence_dir, "candidate_build_delta.csv"))
add_check(
  "bounded_build_delta",
  nrow(candidate_inventory) == 1183L &&
    sum(candidate_inventory$type == "file") == 874L &&
    sum(candidate_inventory$type == "directory") == 309L &&
    sum(candidate_inventory$type == "symlink") == 0L &&
    setequal(added, expected_added) &&
    !length(removed) &&
    setequal(changed, expected_changed),
  sprintf(
    "members=%d added=%d changed=%d removed=%d symlinks=%d",
    nrow(candidate_inventory),
    length(added),
    length(changed),
    length(removed),
    sum(candidate_inventory$type == "symlink")
  )
)

asset_paths <- file.path(candidate_build, names(nav_candidate_asset_hashes))
asset_audit <- data.frame(
  path = names(nav_candidate_asset_hashes),
  expected_sha256 = unname(nav_candidate_asset_hashes),
  live_sha256 = vapply(asset_paths, nav_sha256_file, character(1)),
  expected_bytes = unname(nav_candidate_asset_bytes),
  live_bytes = vapply(asset_paths, nav_file_bytes, numeric(1)),
  stringsAsFactors = FALSE
)
asset_audit$exact <-
  asset_audit$expected_sha256 == asset_audit$live_sha256 &
  asset_audit$expected_bytes == asset_audit$live_bytes
readr::write_csv(
  asset_audit,
  file.path(evidence_dir, "candidate_asset_manifest.csv")
)
add_check(
  "exact_shared_assets",
  nrow(asset_audit) == 3L && all(asset_audit$exact),
  sprintf("exact=%d/3", sum(asset_audit$exact))
)

resolve_target <- function(reference, source_route, build_root) {
  reference <- sub("[?].*$", "", reference)
  path_part <- utils::URLdecode(sub("#.*$", "", reference))
  if (!nzchar(path_part)) {
    return(file.path(build_root, source_route))
  }
  if (startsWith(path_part, "/")) {
    return(file.path(build_root, sub("^/+", "", path_part)))
  }
  file.path(dirname(file.path(build_root, source_route)), path_part)
}

route_from_reference <- function(reference, source_route, build_root) {
  if (
    !nzchar(reference) ||
      grepl("^(?:https?:|mailto:|tel:|javascript:|data:|//|#)",
        reference,
        ignore.case = TRUE,
        perl = TRUE
      )
  ) {
    return(NA_character_)
  }
  target <- normalizePath(
    resolve_target(reference, source_route, build_root),
    winslash = "/",
    mustWork = FALSE
  )
  root <- normalizePath(build_root, winslash = "/", mustWork = TRUE)
  if (!startsWith(target, paste0(root, "/"))) return(NA_character_)
  relative <- substring(target, nchar(root) + 2L)
  if (dir.exists(target)) relative <- file.path(relative, "index.html")
  relative
}

split_header_tokens <- function(values) {
  unlist(lapply(values, function(value) {
    if (is.na(value) || !nzchar(trimws(value))) return(character())
    strsplit(trimws(value), "[[:space:]]+")[[1L]]
  }), use.names = FALSE)
}

audit_document <- function(path) {
  document <- xml2::read_html(path)
  main <- xml2::xml_find_all(document, "//main[@id='quarto-document-content']")
  stopifnot(length(main) == 1L)
  main <- main[[1L]]
  ids <- xml2::xml_attr(
    xml2::xml_find_all(document, "//*[@id and not(ancestor-or-self::svg)]"),
    "id"
  )
  ids <- ids[!is.na(ids) & nzchar(ids)]
  main_ids <- xml2::xml_attr(
    xml2::xml_find_all(main, ".//*[@id and not(ancestor-or-self::svg)]"),
    "id"
  )
  main_ids <- main_ids[!is.na(main_ids) & nzchar(main_ids)]
  tables <- xml2::xml_find_all(
    main,
    paste0(
      ".//table[contains(concat(' ', normalize-space(@class), ' '), ",
      "' gt_table ')]"
    )
  )
  header_tokens <- 0L
  unresolved_headers <- 0L
  if (length(tables)) {
    for (table in tables) {
      table_ids <- xml2::xml_attr(
        xml2::xml_find_all(table, "self::*[@id] | .//*[@id]"),
        "id"
      )
      table_ids <- table_ids[!is.na(table_ids) & nzchar(table_ids)]
      tokens <- split_header_tokens(xml2::xml_attr(
        xml2::xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
        "headers"
      ))
      header_tokens <- header_tokens + length(tokens)
      if (length(tokens)) {
        unresolved_headers <- unresolved_headers + sum(vapply(
          tokens,
          function(token) sum(table_ids == token) != 1L,
          logical(1)
        ))
      }
    }
  }
  figures <- xml2::xml_find_all(main, ".//figure//img")
  figure_alt <- xml2::xml_attr(figures, "alt")
  errors <- xml2::xml_find_all(
    main,
    paste0(
      ".//*[contains(concat(' ', normalize-space(@class), ' '), ",
      "' cell-output-error ') or contains(concat(' ', normalize-space(@class), ",
      "' '), ' quarto-error ')]"
    )
  )
  list(
    document = document,
    main_count = 1L,
    ids = ids,
    duplicate_ids = unique(ids[duplicated(ids)]),
    main_duplicate_ids = unique(main_ids[duplicated(main_ids)]),
    gt_tables = length(tables),
    header_tokens = header_tokens,
    unresolved_header_tokens = unresolved_headers,
    figures = length(figures),
    missing_alt = sum(is.na(figure_alt) | !nzchar(trimws(figure_alt))),
    error_nodes = length(errors)
  )
}

navbar_order_rows <- list()
dom_rows <- list()
link_rows <- list()
protected_rows <- list()
candidate_cache <- new.env(parent = emptyenv())
read_candidate_cached <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (!exists(normalized, envir = candidate_cache, inherits = FALSE)) {
    assign(normalized, xml2::read_html(normalized), envir = candidate_cache)
  }
  get(normalized, envir = candidate_cache, inherits = FALSE)
}

for (index in seq_len(nrow(manifest))) {
  route <- routes[[index]]
  accepted_path <- file.path(project_root, manifest$expected_html[[index]])
  candidate_path <- file.path(candidate_build, route)
  accepted_text <- nav_read_text(accepted_path)
  candidate_text <- nav_read_text(candidate_path)
  accepted_audit <- audit_document(accepted_path)
  candidate_audit <- audit_document(candidate_path)

  protected_exact <- identical(
    nav_protected_main(accepted_text),
    nav_protected_main(candidate_text)
  )
  page_navigation_exact <- identical(
    nav_extract_page_navigation(accepted_text),
    nav_extract_page_navigation(candidate_text)
  )
  protected_rows[[index]] <- data.frame(
    source = manifest$source[[index]],
    route = route,
    protected_main_exact = protected_exact,
    page_navigation_exact = page_navigation_exact,
    stringsAsFactors = FALSE
  )

  document <- candidate_audit$document
  header <- xml2::xml_find_all(document, "//header[@id='quarto-header']")
  navbar <- xml2::xml_find_all(
    document,
    "//header[@id='quarto-header']//ul[contains(concat(' ', normalize-space(@class), ' '), ' navbar-nav ')]"
  )
  navbar_anchors <- if (length(navbar) == 1L) {
    xml2::xml_find_all(navbar[[1L]], ".//a[@href]")
  } else {
    xml2::xml_find_all(document, "//never")
  }
  navbar_hrefs <- xml2::xml_attr(navbar_anchors, "href")
  navbar_routes <- vapply(
    navbar_hrefs,
    route_from_reference,
    character(1),
    source_route = route,
    build_root = candidate_build
  )
  navbar_routes <- navbar_routes[!is.na(navbar_routes) & navbar_routes %in% routes]
  breadcrumb <- xml2::xml_find_all(
    document,
    paste0(
      "//main[@id='quarto-document-content']//nav[contains(concat(' ', ",
      "normalize-space(@class), ' '), ' quarto-title-breadcrumbs ')]"
    )
  )
  breadcrumb_hrefs <- if (length(breadcrumb) == 1L) {
    xml2::xml_attr(xml2::xml_find_all(breadcrumb[[1L]], ".//a[@href]"), "href")
  } else {
    character()
  }
  breadcrumb_routes <- vapply(
    breadcrumb_hrefs,
    route_from_reference,
    character(1),
    source_route = route,
    build_root = candidate_build
  )
  active_nodes <- xml2::xml_find_all(
    navbar_anchors,
    "self::a[contains(concat(' ', normalize-space(@class), ' '), ' active ')]"
  )
  active_hrefs <- xml2::xml_attr(active_nodes, "href")
  active_routes <- vapply(
    active_hrefs,
    route_from_reference,
    character(1),
    source_route = route,
    build_root = candidate_build
  )
  expected_breadcrumb_count <- if (
    route %in% c("index.html", "supplementary_information.html")
  ) 0L else 1L
  active_state <- route %in% navbar_routes &&
    if (identical(route, "index.html")) {
      route %in% active_routes
    } else if (expected_breadcrumb_count == 1L) {
      route %in% breadcrumb_routes
    } else {
      TRUE
    }

  bootstrap_href <- xml2::xml_attr(
    xml2::xml_find_all(document, "//link[@id='quarto-bootstrap']"),
    "href"
  )
  expected_bootstrap <- if (identical(route, "index.html")) {
    "bootstrap-972c31c23100bce3c5dc8576c7cea842.min.css"
  } else {
    "bootstrap-1b8143a5af30aa0587ead8c64582f750.min.css"
  }
  bootstrap_exact <- length(bootstrap_href) == 1L &&
    endsWith(bootstrap_href, expected_bootstrap)

  old_sidebar <- xml2::xml_find_all(document, "//nav[@id='quarto-sidebar']")
  margin_toc <- xml2::xml_find_all(
    document,
    "//div[@id='quarto-margin-sidebar']//nav[@id='TOC']"
  )
  toc_title <- xml2::xml_text(xml2::xml_find_all(
    document,
    "//div[@id='quarto-margin-sidebar']//h2[@id='toc-title']"
  ))
  nathealth_styles <- xml2::xml_find_all(
    document,
    "//link[contains(@href, 'styles-nathealth.css')]"
  )
  mobile_script <- xml2::xml_find_all(
    document,
    "//script[contains(., 'nathealth-mobile-toc')]"
  )
  search_nodes <- xml2::xml_find_all(document, "//*[@id='quarto-search']")
  body_class <- xml2::xml_attr(xml2::xml_find_first(document, "//body"), "class")
  content_class <- xml2::xml_attr(
    xml2::xml_find_first(document, "//div[@id='quarto-content']"),
    "class"
  )
  main_node <- xml2::xml_find_all(
    document,
    "//main[@id='quarto-document-content']"
  )
  title_meta_node <- xml2::xml_find_all(
    main_node,
    paste0(
      ".//div[contains(concat(' ', normalize-space(@class), ' '), ",
      "' quarto-title-meta ')]"
    )
  )
  main_class <- xml2::xml_attr(main_node, "class")
  title_meta_class <- xml2::xml_attr(title_meta_node, "class")
  layout_affected <- route %in% layout_routes
  main_column_page_left <- length(main_class) == 1L && grepl(
    "(?:^| )column-page-left(?: |$)",
    main_class,
    perl = TRUE
  )
  title_meta_column_page_left <- length(title_meta_class) == 1L && grepl(
    "(?:^| )column-page-left(?: |$)",
    title_meta_class,
    perl = TRUE
  )
  main_column_page_right <- length(main_class) == 1L && grepl(
    "(?:^| )column-page-right(?: |$)",
    main_class,
    perl = TRUE
  )
  title_meta_column_page_right <- length(title_meta_class) == 1L && grepl(
    "(?:^| )column-page-right(?: |$)",
    title_meta_class,
    perl = TRUE
  )

  full_duplicate_delta <- setdiff(
    candidate_audit$duplicate_ids,
    accepted_audit$duplicate_ids
  )
  main_semantics_exact <-
    candidate_audit$gt_tables == accepted_audit$gt_tables &&
    candidate_audit$header_tokens == accepted_audit$header_tokens &&
    candidate_audit$unresolved_header_tokens ==
      accepted_audit$unresolved_header_tokens &&
    identical(
      candidate_audit$main_duplicate_ids,
      accepted_audit$main_duplicate_ids
    ) &&
    candidate_audit$figures == accepted_audit$figures &&
    candidate_audit$missing_alt == accepted_audit$missing_alt

  dom_rows[[index]] <- data.frame(
    logical_order = manifest$logical_order[[index]],
    source = manifest$source[[index]],
    route = route,
    header_count = length(header),
    navbar_route_count = length(navbar_routes),
    navbar_route_set_exact = setequal(navbar_routes, routes),
    navbar_route_unique = !anyDuplicated(navbar_routes),
    active_state = active_state,
    breadcrumb_count = length(breadcrumb),
    expected_breadcrumb_count = expected_breadcrumb_count,
    old_sidebar_count = length(old_sidebar),
    margin_toc_count = length(margin_toc),
    toc_title_exact = length(toc_title) == 1L && toc_title == "On this page",
    nathealth_styles_count = length(nathealth_styles),
    mobile_script_count = length(mobile_script),
    search_count = length(search_nodes),
    bootstrap_exact = bootstrap_exact,
    body_nav_fixed = grepl("(?:^| )nav-fixed(?: |$)", body_class, perl = TRUE),
    content_page_navbar = grepl("(?:^| )page-navbar(?: |$)", content_class, perl = TRUE),
    layout_class_affected = layout_affected,
    main_column_page_left = main_column_page_left,
    title_meta_column_page_left = title_meta_column_page_left,
    main_column_page_right = main_column_page_right,
    title_meta_column_page_right = title_meta_column_page_right,
    protected_main_exact = protected_exact,
    page_navigation_exact = page_navigation_exact,
    main_semantics_exact = main_semantics_exact,
    new_duplicate_ids = length(full_duplicate_delta),
    gt_tables = candidate_audit$gt_tables,
    header_tokens = candidate_audit$header_tokens,
    unresolved_header_tokens = candidate_audit$unresolved_header_tokens,
    figures = candidate_audit$figures,
    error_nodes = candidate_audit$error_nodes,
    stringsAsFactors = FALSE
  )
  navbar_order_rows[[index]] <- data.frame(
    source_route = route,
    position = seq_along(navbar_routes),
    target_route = navbar_routes,
    stringsAsFactors = FALSE
  )

  nodes <- xml2::xml_find_all(document, "//*[@href or @src]")
  references <- ifelse(
    !is.na(xml2::xml_attr(nodes, "href")),
    xml2::xml_attr(nodes, "href"),
    xml2::xml_attr(nodes, "src")
  )
  references <- references[!is.na(references) & nzchar(trimws(references))]
  references <- references[!grepl(
    "^(?:https?:|mailto:|tel:|javascript:|data:|//)",
    references,
    ignore.case = TRUE,
    perl = TRUE
  )]
  for (reference in references) {
    reference_no_query <- sub("[?].*$", "", reference)
    fragment <- if (grepl("#", reference_no_query, fixed = TRUE)) {
      utils::URLdecode(sub("^[^#]*#", "", reference_no_query))
    } else {
      ""
    }
    target <- normalizePath(
      resolve_target(reference, route, candidate_build),
      winslash = "/",
      mustWork = FALSE
    )
    normalized_build <- normalizePath(
      candidate_build,
      winslash = "/",
      mustWork = TRUE
    )
    inside <- identical(target, normalized_build) ||
      startsWith(target, paste0(normalized_build, "/"))
    target_file <- if (dir.exists(target)) file.path(target, "index.html") else target
    target_exists <- inside && (file.exists(target) || dir.exists(target))
    fragment_resolves <- TRUE
    if (target_exists && nzchar(fragment)) {
      target_ids <- if (
        file.exists(target_file) && grepl("\\.html?$", target_file, ignore.case = TRUE)
      ) {
        xml2::xml_attr(
          xml2::xml_find_all(read_candidate_cached(target_file), "//*[@id]"),
          "id"
        )
      } else {
        character()
      }
      fragment_resolves <- sum(target_ids == fragment, na.rm = TRUE) == 1L
    }
    link_rows[[length(link_rows) + 1L]] <- data.frame(
      source_route = route,
      reference = reference,
      target = target,
      inside_build = inside,
      target_exists = target_exists,
      fragment = fragment,
      fragment_resolves = fragment_resolves,
      resolved = target_exists && fragment_resolves,
      stringsAsFactors = FALSE
    )
  }
}

dom_audit <- do.call(rbind, dom_rows)
navbar_audit <- do.call(rbind, navbar_order_rows)
link_audit <- do.call(rbind, link_rows)
protected_audit <- do.call(rbind, protected_rows)
readr::write_csv(dom_audit, file.path(evidence_dir, "candidate_dom_audit.csv"))
readr::write_csv(navbar_audit, file.path(evidence_dir, "candidate_navbar_routes.csv"))
readr::write_csv(link_audit, file.path(evidence_dir, "candidate_link_audit.csv"))
readr::write_csv(
  protected_audit,
  file.path(evidence_dir, "candidate_protected_content_audit.csv")
)

navbar_reference <- navbar_audit[
  navbar_audit$source_route == "index.html",
  "target_route",
  drop = TRUE
]
pairs_adjacent <- all(vapply(sprintf("H%02d", 1:11), function(hypothesis) {
  result <- paste0("notebooks/hypotheses/", hypothesis, ".html")
  companion <- paste0(
    "audit/hypotheses/", hypothesis, "/",
    hypothesis, "_analysis_preparation.html"
  )
  match(companion, navbar_reference) == match(result, navbar_reference) + 1L
}, logical(1)))
h06_daily_adjacent <-
  match(
    "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html",
    navbar_reference
  ) ==
  match("notebooks/hypotheses/H06_daily.html", navbar_reference) + 1L

prereg_document <- xml2::read_html(file.path(
  candidate_build,
  "notebooks/preregistration_deviations.html"
))
deviation_ids <- xml2::xml_attr(
  xml2::xml_find_all(
    prereg_document,
    "//section[starts-with(@id, 'dev-') or starts-with(@id, 'imp-') or starts-with(@id, 'doc-') or starts-with(@id, 'rep-')]"
  ),
  "id"
)
deviation_ids <- deviation_ids[grepl("^(?:dev|imp|doc|rep)-[0-9]{3}$", deviation_ids)]

layout_transition_pass <- nrow(transitions) == 37L &&
  !anyDuplicated(transitions$route) &&
  setequal(transitions$route, routes) &&
  sum(transitions$layout_class_affected) == 34L &&
  setequal(
    transitions$route[transitions$layout_class_affected],
    layout_routes
  ) &&
  all(
    transitions$main_right_before ==
      as.integer(transitions$layout_class_affected)
  ) &&
  all(
    transitions$main_layout_replacements ==
      as.integer(transitions$layout_class_affected)
  ) &&
  all(
    transitions$main_left_after ==
      as.integer(transitions$layout_class_affected)
  ) &&
  all(
    transitions$title_meta_right_before ==
      as.integer(transitions$layout_class_affected)
  ) &&
  all(
    transitions$title_meta_layout_replacements ==
      as.integer(transitions$layout_class_affected)
  ) &&
  all(
    transitions$title_meta_left_after ==
      as.integer(transitions$layout_class_affected)
  )
add_check(
  "exact_layout_class_transform",
  layout_transition_pass,
  "affected_paths=34 main_replacements=34 title_meta_replacements=34"
)

dom_pass <- nrow(dom_audit) == 37L &&
  all(dom_audit$header_count == 1L) &&
  all(dom_audit$navbar_route_count == 37L) &&
  all(dom_audit$navbar_route_set_exact) &&
  all(dom_audit$navbar_route_unique) &&
  all(dom_audit$active_state) &&
  all(dom_audit$breadcrumb_count == dom_audit$expected_breadcrumb_count) &&
  all(dom_audit$old_sidebar_count == 0L) &&
  all(dom_audit$margin_toc_count == 1L) &&
  all(dom_audit$toc_title_exact) &&
  all(dom_audit$nathealth_styles_count == 1L) &&
  all(dom_audit$mobile_script_count == 1L) &&
  all(dom_audit$search_count == 1L) &&
  all(dom_audit$bootstrap_exact) &&
  all(dom_audit$body_nav_fixed) &&
  all(dom_audit$content_page_navbar) &&
  all(!dom_audit$main_column_page_right) &&
  all(!dom_audit$title_meta_column_page_right) &&
  all(dom_audit$main_column_page_left[dom_audit$layout_class_affected]) &&
  all(dom_audit$title_meta_column_page_left[dom_audit$layout_class_affected]) &&
  all(dom_audit$protected_main_exact) &&
  all(dom_audit$page_navigation_exact) &&
  all(dom_audit$main_semantics_exact) &&
  all(dom_audit$new_duplicate_ids == 0L) &&
  all(dom_audit$error_nodes == 0L) &&
  sum(dom_audit$gt_tables) == 572L &&
  sum(dom_audit$header_tokens) == 46120L &&
  sum(dom_audit$figures) == 160L &&
  length(deviation_ids) == 86L &&
  !anyDuplicated(deviation_ids)
add_check(
  "all_route_dom_and_scientific_content",
  dom_pass,
  sprintf(
    "routes=%d tables=%d figures=%d anchors=%d",
    nrow(dom_audit),
    sum(dom_audit$gt_tables),
    sum(dom_audit$figures),
    length(deviation_ids)
  )
)
add_check(
  "navbar_contract",
  length(navbar_reference) == 37L &&
    setequal(navbar_reference, routes) &&
    pairs_adjacent && h06_daily_adjacent,
  "routes=37 H01-H11_pairs=11/11 H06_daily_pair=1/1"
)
add_check(
  "all_local_links_and_resources",
  nrow(link_audit) > 10000L &&
    all(link_audit$inside_build) &&
    all(link_audit$target_exists) &&
    all(link_audit$fragment_resolves) &&
    all(link_audit$resolved),
  sprintf(
    "references=%d unresolved=%d outside=%d",
    nrow(link_audit),
    sum(!link_audit$resolved),
    sum(!link_audit$inside_build)
  )
)

preserved_shared <- c("search.json", "sitemap.xml", "robots.txt")
preserved_exact <- vapply(preserved_shared, function(relative) {
  nav_sha256_file(file.path(project_root, "_build/nathealth", relative)) ==
    nav_sha256_file(file.path(candidate_build, relative))
}, logical(1))
add_check(
  "preserved_shared_reader_files",
  all(preserved_exact),
  paste0(preserved_shared, "=exact", collapse = " ")
)

if (identical(phase, "final")) {
  route_qa_path <- file.path(evidence_dir, "candidate_browser_route_qa.json")
  manual_qa_path <- file.path(evidence_dir, "candidate_browser_manual_qa.csv")
  loopback_path <- file.path(evidence_dir, "candidate_loopback_qa.csv")
  stopifnot(file.exists(route_qa_path), file.exists(manual_qa_path), file.exists(loopback_path))
  route_qa <- jsonlite::fromJSON(route_qa_path, simplifyDataFrame = TRUE)
  manual_qa <- readr::read_csv(manual_qa_path, show_col_types = FALSE)
  loopback_qa <- readr::read_csv(loopback_path, show_col_types = FALSE)
  route_browser_pass <- nrow(route_qa) == 74L &&
    setequal(route_qa$route, routes) &&
    setequal(route_qa$viewport_width, c(390L, 1440L)) &&
    !anyDuplicated(paste(route_qa$route, route_qa$viewport_width)) &&
    all(route_qa$http_ok) &&
    all(route_qa$navbar_routes == 37L) &&
    all(route_qa$header_count == 1L) &&
    all(route_qa$toc_count == 1L) &&
    all(route_qa$mobile_toc_ready) &&
    all(route_qa$desktop_toc_fixed[route_qa$viewport_width == 1440L]) &&
    all(route_qa$mobile_toc_collapsed[route_qa$viewport_width == 390L]) &&
    all(route_qa$title_meta_aligned) &&
    all(route_qa$console_errors == 0L) &&
    all(!route_qa$page_overflow)
  manual_browser_pass <- nrow(manual_qa) == 15L &&
    setequal(manual_qa$viewport_width, c(390L, 708L, 1440L)) &&
    length(unique(manual_qa$route)) == 5L &&
    !anyDuplicated(paste(manual_qa$route, manual_qa$viewport_width)) &&
    all(manual_qa$pass)
  loopback_pass <- nrow(loopback_qa) == 1L &&
    loopback_qa$pre_serve_symlinks == 0L &&
    loopback_qa$served_candidate_only &&
    loopback_qa$server_stopped &&
    loopback_qa$listener_cleared
  add_check(
    "candidate_browser_all_routes",
    route_browser_pass,
    sprintf("rows=%d routes=37 widths=390/1440", nrow(route_qa))
  )
  add_check(
    "candidate_browser_manual_matrix",
    manual_browser_pass,
    sprintf("rows=%d route_classes=5 widths=390/708/1440", nrow(manual_qa))
  )
  add_check(
    "candidate_secure_loopback",
    loopback_pass,
    "candidate_only=TRUE symlinks=0 server_stopped=TRUE listener_cleared=TRUE"
  )
}

checks_frame <- do.call(rbind, checks)
expected_checks <- if (identical(phase, "final")) 10L else 7L
expected_checks <- expected_checks + 1L
readr::write_csv(
  checks_frame,
  file.path(evidence_dir, paste0("candidate_checks_", phase, ".csv"))
)
stopifnot(nrow(checks_frame) == expected_checks, all(checks_frame$pass))

if (identical(phase, "final")) {
  sealed_candidate <- unique(c(
    file.path(candidate_build, routes),
    file.path(candidate_build, names(nav_candidate_asset_hashes))
  ))
  candidate_manifest <- data.frame(
    path = c(routes, names(nav_candidate_asset_hashes)),
    sha256 = vapply(sealed_candidate, nav_sha256_file, character(1)),
    bytes = vapply(sealed_candidate, nav_file_bytes, numeric(1)),
    stringsAsFactors = FALSE
  )
  readr::write_csv(
    candidate_manifest,
    file.path(evidence_dir, "candidate_promotion_manifest.csv")
  )
}

cat(sprintf(
  paste0(
    "NAVIGATION_CANDIDATE_GATE=%s checks=%d/%d routes=37 ",
    "tables=572 figures=160 anchors=86 symlinks=0 R=%s\n"
  ),
  toupper(phase),
  sum(checks_frame$pass),
  nrow(checks_frame),
  as.character(getRversion())
))
