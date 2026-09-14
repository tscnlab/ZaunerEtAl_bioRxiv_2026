#!/usr/bin/env Rscript

# Navigation-specific postflight. It independently re-reads the promoted live
# HTML and never invokes Quarto or research code.

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
backup_root <- file.path(candidate_root, "promotion_backup")
live_build <- file.path(project_root, "_build/nathealth")

checks <- list()
add_check <- function(check_id, pass, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check_id = check_id,
    pass = isTRUE(pass),
    detail = as.character(detail),
    stringsAsFactors = FALSE
  )
}

promotion <- readr::read_csv(
  file.path(evidence_dir, "promotion_execution.csv"),
  show_col_types = FALSE
)
reseal <- readr::read_csv(
  file.path(evidence_dir, "manifest_reseal_execution.csv"),
  show_col_types = FALSE
)
add_check(
  "single_promotion_and_navigation_manifest_reseal",
  nrow(promotion) == 1L &&
    promotion$execution_count == 1L &&
    promotion$promoted_html == 37L &&
    promotion$promoted_new_assets == 3L &&
    nrow(reseal) == 1L &&
    reseal$resealer_execution_count == 1L &&
    reseal$rows == 37L &&
    reseal$historical_source_hashes_retained == 37L &&
    reseal$html_hashes_changed == 37L &&
    reseal$html_hashes_live_exact == 37L,
  "promotion=1 html=37 assets=3 navigation_resealer=1 rows=37"
)

manifest <- readr::read_csv(
  "audit/report_harmonization/phase4_corpus_manifest.csv",
  show_col_types = FALSE
)
historical <- readr::read_csv(
  file.path(evidence_dir, "historical_phase4_corpus_manifest_pre.csv"),
  show_col_types = FALSE
)
routes <- vapply(manifest$expected_html, nav_html_route, character(1))
transitions <- readr::read_csv(
  file.path(evidence_dir, "candidate_html_transitions.csv"),
  show_col_types = FALSE
)
layout_routes <- transitions$route[transitions$layout_class_affected]
html_live <- vapply(manifest$expected_html, nav_sha256_file, character(1))
source_provenance_columns <- setdiff(
  names(historical),
  c("html_exists", "html_sha256")
)
allowlist <- nav_load_authorized_source_allowlist(evidence_dir, historical)
h09_protected_allowlist <- readr::read_csv(
  file.path(evidence_dir, "h09_concurrent_package_production_allowlist.csv"),
  show_col_types = FALSE
)
external_protected_allowlist <- readr::read_csv(
  file.path(evidence_dir, "navigation_external_protected_checkpoint.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(h09_protected_allowlist) == 8L,
  !anyDuplicated(h09_protected_allowlist$path),
  nrow(external_protected_allowlist) == 3L,
  !anyDuplicated(external_protected_allowlist$path),
  !length(intersect(
    h09_protected_allowlist$path,
    external_protected_allowlist$path
  ))
)
source_checkpoint <- nav_live_source_checkpoint(historical, project_root)
source_drift <- nav_source_drift_audit(source_checkpoint, allowlist)
checkpoint_suffix <- if (identical(phase, "prebrowser")) "pre_qa" else "post_qa"
readr::write_csv(
  source_checkpoint,
  file.path(
    evidence_dir,
    paste0("live_authoring_source_checkpoint_", checkpoint_suffix, ".csv")
  )
)
readr::write_csv(
  source_drift,
  file.path(
    evidence_dir,
    paste0("authorized_source_drift_", checkpoint_suffix, ".csv")
  )
)
add_check(
  "resealed_manifest_live",
  nrow(manifest) == 37L &&
    !anyDuplicated(manifest$source) &&
    !anyDuplicated(manifest$expected_html) &&
    identical(manifest[source_provenance_columns], historical[source_provenance_columns]) &&
    all(manifest$html_sha256 == html_live) &&
    all(source_drift$authorized) &&
    !length(setdiff(source_drift$path, allowlist$path)) &&
    identical(as.integer(manifest$render_position), c(36L, 37L, seq_len(35L))) &&
    identical(as.integer(manifest$sidebar_position), seq_len(37L)),
  sprintf(
    "manifest=%s sources=37/37 html=37/37",
    nav_sha256_file("audit/report_harmonization/phase4_corpus_manifest.csv")
  )
)

pre_build <- readr::read_csv(
  file.path(evidence_dir, "build_inventory_pre.csv"),
  show_col_types = FALSE
)
candidate_build <- readr::read_csv(
  file.path(evidence_dir, "candidate_build_inventory.csv"),
  show_col_types = FALSE
)
live_inventory <- nav_inventory_tree(live_build)
readr::write_csv(
  live_inventory,
  file.path(evidence_dir, paste0("postflight_build_inventory_", phase, ".csv"))
)
pre_paths <- pre_build$path
live_paths <- live_inventory$path
added <- setdiff(live_paths, pre_paths)
removed <- setdiff(pre_paths, live_paths)
common <- intersect(pre_paths, live_paths)
changed <- common[vapply(common, function(path) {
  first <- pre_build[pre_build$path == path, , drop = FALSE]
  second <- live_inventory[live_inventory$path == path, , drop = FALSE]
  !nav_inventories_identical(first, second)
}, logical(1))]
add_check(
  "exact_promoted_build_delta",
  nav_inventories_identical(live_inventory, candidate_build) &&
    nrow(live_inventory) == 1183L &&
    sum(live_inventory$type == "file") == 874L &&
    sum(live_inventory$type == "directory") == 309L &&
    sum(live_inventory$type == "symlink") == 0L &&
    setequal(added, names(nav_candidate_asset_hashes)) &&
    !length(removed) &&
    setequal(changed, routes),
  sprintf(
    "members=%d added=%d changed=%d removed=%d symlinks=%d",
    nrow(live_inventory),
    length(added),
    length(changed),
    length(removed),
    sum(live_inventory$type == "symlink")
  )
)

asset_paths <- file.path(live_build, names(nav_candidate_asset_hashes))
asset_exact <- all(vapply(asset_paths, nav_sha256_file, character(1)) ==
  unname(nav_candidate_asset_hashes)) &&
  all(vapply(asset_paths, nav_file_bytes, numeric(1)) ==
    unname(nav_candidate_asset_bytes))
preserved_shared <- c("search.json", "sitemap.xml", "robots.txt")
preserved_exact <- vapply(preserved_shared, function(relative) {
  pre <- pre_build[pre_build$path == relative, , drop = FALSE]
  nrow(pre) == 1L &&
    nav_sha256_file(file.path(live_build, relative)) == pre$sha256[[1L]] &&
    nav_file_bytes(file.path(live_build, relative)) == pre$bytes[[1L]]
}, logical(1))
add_check(
  "shared_assets_search_sitemap_robots",
  asset_exact && all(preserved_exact),
  "assets=3/3 search=exact sitemap=exact robots=exact"
)

resolve_reference <- function(reference, source_route) {
  reference <- sub("[?].*$", "", reference)
  path_part <- utils::URLdecode(sub("#.*$", "", reference))
  if (!nzchar(path_part)) return(file.path(live_build, source_route))
  if (startsWith(path_part, "/")) {
    return(file.path(live_build, sub("^/+", "", path_part)))
  }
  file.path(dirname(file.path(live_build, source_route)), path_part)
}

route_target <- function(reference, source_route) {
  if (
    !nzchar(reference) ||
      grepl("^(?:https?:|mailto:|tel:|javascript:|data:|//|#)",
        reference,
        ignore.case = TRUE,
        perl = TRUE
      )
  ) return(NA_character_)
  target <- normalizePath(
    resolve_reference(reference, source_route),
    winslash = "/",
    mustWork = FALSE
  )
  root <- normalizePath(live_build, winslash = "/", mustWork = TRUE)
  if (!startsWith(target, paste0(root, "/"))) return(NA_character_)
  relative <- substring(target, nchar(root) + 2L)
  if (dir.exists(target)) relative <- file.path(relative, "index.html")
  relative
}

document_cache <- new.env(parent = emptyenv())
read_cached <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (!exists(normalized, envir = document_cache, inherits = FALSE)) {
    assign(normalized, xml2::read_html(normalized), envir = document_cache)
  }
  get(normalized, envir = document_cache, inherits = FALSE)
}

dom_rows <- list()
link_rows <- list()
for (index in seq_len(nrow(manifest))) {
  route <- routes[[index]]
  live_path <- file.path(live_build, route)
  backup_path <- file.path(backup_root, route)
  text <- nav_read_text(live_path)
  backup_text <- nav_read_text(backup_path)
  document <- read_cached(live_path)
  main <- xml2::xml_find_all(document, "//main[@id='quarto-document-content']")
  stopifnot(length(main) == 1L)
  main <- main[[1L]]
  tables <- xml2::xml_find_all(
    main,
    paste0(
      ".//table[contains(concat(' ', normalize-space(@class), ' '), ",
      "' gt_table ')]"
    )
  )
  header_tokens <- 0L
  unresolved_header_tokens <- 0L
  if (length(tables)) {
    for (table_index in seq_along(tables)) {
      table <- tables[[table_index]]
      table_ids <- xml2::xml_attr(
        xml2::xml_find_all(table, "self::*[@id] | .//*[@id]"),
        "id"
      )
      table_ids <- table_ids[!is.na(table_ids) & nzchar(table_ids)]
      header_values <- xml2::xml_attr(
        xml2::xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
        "headers"
      )
      tokens <- unlist(lapply(header_values, function(value) {
        if (is.na(value) || !nzchar(trimws(value))) return(character())
        strsplit(trimws(value), "[[:space:]]+")[[1L]]
      }), use.names = FALSE)
      header_tokens <- header_tokens + length(tokens)
      unresolved_header_tokens <- unresolved_header_tokens + sum(vapply(
        tokens,
        function(token) sum(table_ids == token) != 1L,
        logical(1)
      ))
    }
  }
  figures <- xml2::xml_find_all(main, ".//figure//img")
  errors <- xml2::xml_find_all(
    main,
    paste0(
      ".//*[contains(concat(' ', normalize-space(@class), ' '), ",
      "' cell-output-error ') or contains(concat(' ', normalize-space(@class), ",
      "' '), ' quarto-error ')]"
    )
  )
  navbar <- xml2::xml_find_all(
    document,
    "//header[@id='quarto-header']//ul[contains(concat(' ', normalize-space(@class), ' '), ' navbar-nav ')]"
  )
  navbar_hrefs <- if (length(navbar) == 1L) {
    xml2::xml_attr(xml2::xml_find_all(navbar[[1L]], ".//a[@href]"), "href")
  } else character()
  navbar_routes <- vapply(
    navbar_hrefs,
    route_target,
    character(1),
    source_route = route
  )
  navbar_routes <- navbar_routes[!is.na(navbar_routes) & navbar_routes %in% routes]
  breadcrumbs <- xml2::xml_find_all(
    document,
    paste0(
      "//main[@id='quarto-document-content']//nav[contains(concat(' ', ",
      "normalize-space(@class), ' '), ' quarto-title-breadcrumbs ')]"
    )
  )
  toc <- xml2::xml_find_all(
    document,
    "//div[@id='quarto-margin-sidebar']//nav[@id='TOC']"
  )
  title_meta <- xml2::xml_find_all(
    main,
    paste0(
      ".//div[contains(concat(' ', normalize-space(@class), ' '), ",
      "' quarto-title-meta ')]"
    )
  )
  main_class <- xml2::xml_attr(main, "class")
  title_meta_class <- xml2::xml_attr(title_meta, "class")
  layout_affected <- route %in% layout_routes
  ids <- xml2::xml_attr(
    xml2::xml_find_all(document, "//*[@id and not(ancestor-or-self::svg)]"),
    "id"
  )
  ids <- ids[!is.na(ids) & nzchar(ids)]
  candidate_row <- readr::read_csv(
    file.path(evidence_dir, "candidate_dom_audit.csv"),
    show_col_types = FALSE
  )
  candidate_row <- candidate_row[candidate_row$route == route, , drop = FALSE]
  dom_rows[[index]] <- data.frame(
    route = route,
    protected_main_exact = identical(
      nav_protected_main(text),
      nav_protected_main(backup_text)
    ),
    page_navigation_exact = identical(
      nav_extract_page_navigation(text),
      nav_extract_page_navigation(backup_text)
    ),
    header_count = length(xml2::xml_find_all(document, "//header[@id='quarto-header']")),
    navbar_routes = length(navbar_routes),
    navbar_exact = setequal(navbar_routes, routes) && !anyDuplicated(navbar_routes),
    breadcrumb_count = length(breadcrumbs),
    expected_breadcrumb_count = if (
      route %in% c("index.html", "supplementary_information.html")
    ) 0L else 1L,
    toc_count = length(toc),
    layout_class_affected = layout_affected,
    main_column_page_left = length(main_class) == 1L && grepl(
      "(?:^| )column-page-left(?: |$)", main_class, perl = TRUE
    ),
    title_meta_column_page_left = length(title_meta_class) == 1L && grepl(
      "(?:^| )column-page-left(?: |$)", title_meta_class, perl = TRUE
    ),
    main_column_page_right = length(main_class) == 1L && grepl(
      "(?:^| )column-page-right(?: |$)", main_class, perl = TRUE
    ),
    title_meta_column_page_right = length(title_meta_class) == 1L && grepl(
      "(?:^| )column-page-right(?: |$)", title_meta_class, perl = TRUE
    ),
    old_sidebar_count = length(xml2::xml_find_all(document, "//nav[@id='quarto-sidebar']")),
    styles_count = length(xml2::xml_find_all(document, "//link[contains(@href, 'styles-nathealth.css')]")),
    mobile_script_count = length(xml2::xml_find_all(document, "//script[contains(., 'nathealth-mobile-toc')]")),
    duplicate_ids = length(unique(ids[duplicated(ids)])),
    candidate_duplicate_ids = candidate_row$new_duplicate_ids[[1L]],
    gt_tables = length(tables),
    header_tokens = header_tokens,
    unresolved_header_tokens = unresolved_header_tokens,
    figures = length(figures),
    error_nodes = length(errors),
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
    no_query <- sub("[?].*$", "", reference)
    fragment <- if (grepl("#", no_query, fixed = TRUE)) {
      utils::URLdecode(sub("^[^#]*#", "", no_query))
    } else ""
    target <- normalizePath(
      resolve_reference(reference, route),
      winslash = "/",
      mustWork = FALSE
    )
    root <- normalizePath(live_build, winslash = "/", mustWork = TRUE)
    inside <- identical(target, root) || startsWith(target, paste0(root, "/"))
    target_file <- if (dir.exists(target)) file.path(target, "index.html") else target
    target_exists <- inside && (file.exists(target) || dir.exists(target))
    fragment_resolves <- TRUE
    if (target_exists && nzchar(fragment)) {
      target_ids <- if (
        file.exists(target_file) && grepl("\\.html?$", target_file, ignore.case = TRUE)
      ) {
        xml2::xml_attr(xml2::xml_find_all(read_cached(target_file), "//*[@id]"), "id")
      } else character()
      fragment_resolves <- sum(target_ids == fragment, na.rm = TRUE) == 1L
    }
    link_rows[[length(link_rows) + 1L]] <- data.frame(
      source_route = route,
      reference = reference,
      inside_build = inside,
      target_exists = target_exists,
      fragment_resolves = fragment_resolves,
      resolved = target_exists && fragment_resolves,
      stringsAsFactors = FALSE
    )
  }
}

dom_audit <- do.call(rbind, dom_rows)
link_audit <- do.call(rbind, link_rows)
readr::write_csv(
  dom_audit,
  file.path(evidence_dir, paste0("postflight_dom_audit_", phase, ".csv"))
)
readr::write_csv(
  link_audit,
  file.path(evidence_dir, paste0("postflight_link_audit_", phase, ".csv"))
)
deviation_document <- read_cached(file.path(
  live_build,
  "notebooks/preregistration_deviations.html"
))
deviation_ids <- xml2::xml_attr(
  xml2::xml_find_all(
    deviation_document,
    "//section[starts-with(@id, 'dev-') or starts-with(@id, 'imp-') or starts-with(@id, 'doc-') or starts-with(@id, 'rep-')]"
  ),
  "id"
)
deviation_ids <- deviation_ids[grepl("^(?:dev|imp|doc|rep)-[0-9]{3}$", deviation_ids)]
add_check(
  "live_dom_tables_figures_navigation",
  nrow(dom_audit) == 37L &&
    all(dom_audit$protected_main_exact) &&
    all(dom_audit$page_navigation_exact) &&
    all(dom_audit$header_count == 1L) &&
    all(dom_audit$navbar_routes == 37L) &&
    all(dom_audit$navbar_exact) &&
    all(dom_audit$breadcrumb_count == dom_audit$expected_breadcrumb_count) &&
    all(dom_audit$toc_count == 1L) &&
    all(!dom_audit$main_column_page_right) &&
    all(!dom_audit$title_meta_column_page_right) &&
    all(dom_audit$main_column_page_left[dom_audit$layout_class_affected]) &&
    all(dom_audit$title_meta_column_page_left[dom_audit$layout_class_affected]) &&
    all(dom_audit$old_sidebar_count == 0L) &&
    all(dom_audit$styles_count == 1L) &&
    all(dom_audit$mobile_script_count == 1L) &&
    all(dom_audit$candidate_duplicate_ids == 0L) &&
    all(dom_audit$error_nodes == 0L) &&
    sum(dom_audit$gt_tables) == 572L &&
    sum(dom_audit$header_tokens) == 46120L &&
    sum(dom_audit$figures) == 160L &&
    length(deviation_ids) == 86L &&
    !anyDuplicated(deviation_ids),
  sprintf(
    "routes=37 tables=%d figures=%d anchors=%d",
    sum(dom_audit$gt_tables),
    sum(dom_audit$figures),
    length(deviation_ids)
  )
)
add_check(
  "live_local_links_resources_downloads",
  nrow(link_audit) > 10000L && all(link_audit$resolved) &&
    all(link_audit$inside_build) && all(link_audit$target_exists) &&
    all(link_audit$fragment_resolves),
  sprintf("references=%d unresolved=%d", nrow(link_audit), sum(!link_audit$resolved))
)

protected_pre <- readr::read_csv(
  file.path(evidence_dir, "protected_inventory_pre.csv"),
  show_col_types = FALSE
)
protected_paths <- nav_collect_protected_paths(project_root, evidence_dir)
protected_post <- nav_inventory_paths(protected_paths, project_root)
readr::write_csv(
  protected_post,
  file.path(evidence_dir, paste0("protected_inventory_", phase, ".csv"))
)
common_protected <- intersect(protected_pre$path, protected_post$path)
protected_changed <- common_protected[vapply(common_protected, function(path) {
  first <- protected_pre[protected_pre$path == path, , drop = FALSE]
  second <- protected_post[protected_post$path == path, , drop = FALSE]
  !nav_inventories_identical(first, second)
}, logical(1))]
protected_added <- setdiff(protected_post$path, protected_pre$path)
protected_removed <- setdiff(protected_pre$path, protected_post$path)
expected_protected_added <- h09_protected_allowlist$path[
  h09_protected_allowlist$preflight_state == "absent"
]
expected_protected_changed <- c(
  h09_protected_allowlist$path[
    h09_protected_allowlist$preflight_state == "present"
  ],
  external_protected_allowlist$path,
  "audit/report_harmonization/phase4_corpus_manifest.csv"
)
authorized_protected_paths <- c(
  h09_protected_allowlist$path,
  external_protected_allowlist$path
)
authorized_protected_sha256 <- c(
  h09_protected_allowlist$production_sha256,
  external_protected_allowlist$checkpoint_sha256
)
authorized_protected_bytes <- c(
  h09_protected_allowlist$production_bytes,
  external_protected_allowlist$checkpoint_bytes
)
authorized_protected_exact <-
  all(file.exists(authorized_protected_paths)) &&
  !any(dir.exists(authorized_protected_paths)) &&
  !any(nzchar(Sys.readlink(authorized_protected_paths))) &&
  all(vapply(
    authorized_protected_paths,
    nav_sha256_file,
    character(1)
  ) == authorized_protected_sha256) &&
  all(vapply(
    authorized_protected_paths,
    nav_file_bytes,
    numeric(1)
  ) == authorized_protected_bytes)
pinned_live <- vapply(
  names(nav_pinned_identities)[1:4],
  nav_sha256_file,
  character(1)
)
add_check(
  "protected_science_source_profile_lock",
  setequal(protected_added, expected_protected_added) &&
    !length(protected_removed) &&
    setequal(protected_changed, expected_protected_changed) &&
    authorized_protected_exact &&
    all(pinned_live == unname(nav_pinned_identities[1:4])) &&
    identical(manifest$source_sha256, historical$source_sha256) &&
    all(source_drift$authorized),
  sprintf(
    paste0(
      "changed=%d authorized_added=%d removed=%d protected_exact=%d/%d ",
      "accepted_source_hashes_retained=37/37 live_source_drift=%d"
    ),
    length(protected_changed),
    length(protected_added),
    length(protected_removed),
    sum(vapply(
      authorized_protected_paths,
      nav_sha256_file,
      character(1)
    ) == authorized_protected_sha256),
    length(authorized_protected_paths),
    nrow(source_drift)
  )
)

if (identical(phase, "prebrowser")) {
  readr::write_csv(
    live_inventory,
    file.path(evidence_dir, "postflight_build_inventory_pre_qa.csv")
  )
} else {
  route_qa <- jsonlite::fromJSON(
    file.path(evidence_dir, "postflight_browser_route_qa.json"),
    simplifyDataFrame = TRUE
  )
  manual_qa <- readr::read_csv(
    file.path(evidence_dir, "postflight_browser_manual_qa.csv"),
    show_col_types = FALSE
  )
  loopback_qa <- readr::read_csv(
    file.path(evidence_dir, "postflight_loopback_qa.csv"),
    show_col_types = FALSE
  )
  pre_qa_inventory <- readr::read_csv(
    file.path(evidence_dir, "postflight_build_inventory_pre_qa.csv"),
    show_col_types = FALSE
  )
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
    loopback_qa$served_live_build_only &&
    loopback_qa$tabs_closed &&
    loopback_qa$viewport_restored &&
    loopback_qa$server_stopped &&
    loopback_qa$listener_cleared
  stability_pass <- nav_inventories_identical(pre_qa_inventory, live_inventory)
  add_check(
    "postflight_browser_all_routes",
    route_browser_pass,
    sprintf("rows=%d routes=37 widths=390/1440", nrow(route_qa))
  )
  add_check(
    "postflight_browser_manual_matrix",
    manual_browser_pass,
    sprintf("rows=%d route_classes=5 widths=390/708/1440", nrow(manual_qa))
  )
  add_check(
    "postflight_secure_loopback_and_stability",
    loopback_pass && stability_pass,
    paste0(
      "live_only=TRUE symlinks=0 tabs_closed=TRUE viewport_restored=TRUE ",
      "server_stopped=TRUE listener_cleared=TRUE build_stable=TRUE"
    )
  )
}

checks_frame <- do.call(rbind, checks)
expected_checks <- if (identical(phase, "final")) 10L else 7L
readr::write_csv(
  checks_frame,
  file.path(evidence_dir, paste0("postflight_checks_", phase, ".csv"))
)
stopifnot(nrow(checks_frame) == expected_checks, all(checks_frame$pass))

cat(sprintf(
  paste0(
    "NAVIGATION_POSTFLIGHT=%s checks=%d/%d routes=37 tables=572 ",
    "figures=160 anchors=86 build=1183 symlinks=0 R=%s\n"
  ),
  toupper(phase),
  sum(checks_frame$pass),
  nrow(checks_frame),
  as.character(getRversion())
))
