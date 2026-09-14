# Shared infrastructure helpers for the bounded Nature Health navigation
# integration. These functions inspect files and HTML structure only. They do
# not source research code or calculate scientific results.

nav_integration_evidence_rel <- file.path(
  "audit",
  "report_harmonization",
  "navigation_integration_2026_08_24"
)

nav_pinned_identities <- c(
  "_quarto-nathealth.yml" =
    "e54c71794f4f763a8b50417ab83ff3db37bc9af3fef3f4d1910576ab12c61bc7",
  "styles-nathealth.css" =
    "051d9468f636df71e2408687661369a443029407426fef98850ff56def9aac87",
  "_includes/nathealth-mobile-toc.html" =
    "926a5fc051f032100714ae01b53c5ba2937c91ff2406ab5354484bf8fd7f553d",
  "scripts/report_harmonization/build_phase4_corpus_manifest.R" =
    "c01f0dc86e25bcf4a37685515cd692e2007774a004a4e902eac5936521749e2e",
  "audit/report_harmonization/phase4_corpus_manifest.csv" =
    "983b16136c1115d5a6b8dceb135c10de8d347743c694c5027c4ead9b2c7aa605"
)

nav_candidate_asset_hashes <- c(
  "styles-nathealth.css" =
    "051d9468f636df71e2408687661369a443029407426fef98850ff56def9aac87",
  "site_libs/bootstrap/bootstrap-972c31c23100bce3c5dc8576c7cea842.min.css" =
    "0a74a0ddb6fe002656dc2f13792ae79a8d118975928596ecde7405a1e942b6b9",
  "site_libs/bootstrap/bootstrap-1b8143a5af30aa0587ead8c64582f750.min.css" =
    "9999987d3d7add3f1378d1f9def4045d85cd9fda0679f9bd14be58a69dc0ceef"
)

nav_candidate_asset_bytes <- c(
  "styles-nathealth.css" = 4548,
  "site_libs/bootstrap/bootstrap-972c31c23100bce3c5dc8576c7cea842.min.css" =
    498388,
  "site_libs/bootstrap/bootstrap-1b8143a5af30aa0587ead8c64582f750.min.css" =
    498388
)

nav_authorized_concurrent_source_status <-
  "AUTHORIZED_CONCURRENT_SOURCE_ONLY_NOT_RENDERED"

nav_authorized_concurrent_source_seed <- data.frame(
  path = "notebooks/hypotheses/H09.qmd",
  role = "hypothesis_result",
  owner_task_authority = "019fdc1b-b927-7fb1-ac61-88993c0a818a",
  status = nav_authorized_concurrent_source_status,
  stringsAsFactors = FALSE
)

nav_sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

nav_file_bytes <- function(path) {
  unname(as.numeric(file.info(path)$size))
}

nav_read_text <- function(path) {
  size <- nav_file_bytes(path)
  rawToChar(readBin(path, what = "raw", n = size))
}

nav_write_text_atomic <- function(text, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    paste0(basename(path), "."),
    tmpdir = dirname(path)
  )
  connection <- file(temporary, open = "wb")
  connection_open <- TRUE
  on.exit({
    if (connection_open) close(connection)
    if (file.exists(temporary)) unlink(temporary)
  }, add = TRUE)
  writeBin(charToRaw(enc2utf8(text)), connection)
  close(connection)
  connection_open <- FALSE
  if (!file.rename(temporary, path)) {
    stop("Could not atomically replace ", path, call. = FALSE)
  }
  invisible(path)
}

nav_copy_file_exact <- function(source, target) {
  stopifnot(file.exists(source), !dir.exists(source))
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    paste0(basename(target), "."),
    tmpdir = dirname(target)
  )
  on.exit(if (file.exists(temporary)) unlink(temporary), add = TRUE)
  stopifnot(file.copy(source, temporary, overwrite = TRUE, copy.mode = TRUE))
  stopifnot(nav_sha256_file(temporary) == nav_sha256_file(source))
  if (!file.rename(temporary, target)) {
    stop("Could not atomically copy ", source, " to ", target, call. = FALSE)
  }
  invisible(target)
}

nav_relative_to <- function(path, root) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  normalized_root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  prefix <- paste0(normalized_root, "/")
  stopifnot(startsWith(normalized, prefix))
  substring(normalized, nchar(prefix) + 1L)
}

nav_inventory_tree <- function(root) {
  normalized_root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  members <- sort(list.files(
    normalized_root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  ))
  links <- Sys.readlink(members)
  info <- file.info(members)
  is_file <- !is.na(info$isdir) & !info$isdir
  hashes <- rep(NA_character_, length(members))
  hashes[is_file & !nzchar(links)] <- vapply(
    members[is_file & !nzchar(links)],
    nav_sha256_file,
    character(1)
  )
  bytes <- rep(NA_real_, length(members))
  bytes[is_file] <- unname(as.numeric(info$size[is_file]))
  data.frame(
    path = substring(members, nchar(normalized_root) + 2L),
    type = ifelse(nzchar(links), "symlink", ifelse(is_file, "file", "directory")),
    sha256 = hashes,
    bytes = bytes,
    link_target = links,
    stringsAsFactors = FALSE
  )
}

nav_inventory_paths <- function(paths, project_root) {
  paths <- sort(unique(paths[file.exists(paths) & !dir.exists(paths)]))
  links <- Sys.readlink(paths)
  hashes <- rep(NA_character_, length(paths))
  regular <- !nzchar(links)
  hashes[regular] <- vapply(paths[regular], nav_sha256_file, character(1))
  data.frame(
    path = vapply(paths, nav_relative_to, character(1), root = project_root),
    type = ifelse(regular, "file", "symlink"),
    sha256 = hashes,
    bytes = unname(as.numeric(file.info(paths)$size)),
    link_target = links,
    stringsAsFactors = FALSE
  )
}

nav_live_source_checkpoint <- function(manifest, project_root) {
  paths <- file.path(project_root, manifest$source)
  stopifnot(all(file.exists(paths)), !any(dir.exists(paths)))
  info <- file.info(paths)
  data.frame(
    logical_order = manifest$logical_order,
    path = manifest$source,
    role = manifest$role,
    accepted_source_sha256 = manifest$source_sha256,
    live_source_sha256 = vapply(paths, nav_sha256_file, character(1)),
    live_bytes = unname(as.numeric(info$size)),
    live_mtime_utc = format(info$mtime, tz = "UTC", usetz = TRUE),
    stringsAsFactors = FALSE
  )
}

nav_load_authorized_source_allowlist <- function(evidence_dir, manifest) {
  path <- file.path(evidence_dir, "authorized_concurrent_source_allowlist.csv")
  if (!file.exists(path)) {
    readr::write_csv(nav_authorized_concurrent_source_seed, path)
  }
  allowlist <- readr::read_csv(path, show_col_types = FALSE)
  stopifnot(
    identical(
      names(allowlist),
      c("path", "role", "owner_task_authority", "status")
    ),
    !anyDuplicated(allowlist$path),
    all(allowlist$path %in% manifest$source),
    all(allowlist$status == nav_authorized_concurrent_source_status),
    all(nzchar(allowlist$owner_task_authority)),
    all(grepl(
      paste0(
        "^(?:notebooks/hypotheses/H[0-9]{2}(?:_daily)?|",
        "audit/hypotheses/H[0-9]{2}(?:_daily)?/",
        "H[0-9]{2}(?:_daily)?_analysis_preparation)\\.qmd$"
      ),
      allowlist$path,
      perl = TRUE
    ))
  )
  expected_roles <- manifest$role[match(allowlist$path, manifest$source)]
  stopifnot(identical(as.character(allowlist$role), as.character(expected_roles)))
  allowlist
}

nav_source_drift_audit <- function(checkpoint, allowlist) {
  drift <- checkpoint[
    checkpoint$accepted_source_sha256 != checkpoint$live_source_sha256,
    ,
    drop = FALSE
  ]
  authority_index <- match(drift$path, allowlist$path)
  drift$owner_task_authority <- allowlist$owner_task_authority[authority_index]
  drift$status <- allowlist$status[authority_index]
  drift$authorized <- !is.na(authority_index) &
    drift$status == nav_authorized_concurrent_source_status
  drift
}

nav_classify_protected_inventory <- function(inventory, authorized_paths) {
  inventory$navigation_classification <- ifelse(
    inventory$path %in% authorized_paths,
    "AUTHORIZED_CONCURRENT_SOURCE_ONLY",
    "NAVIGATION_FIXED_EXACT"
  )
  inventory
}

nav_inventory_signature <- function(inventory) {
  inventory <- as.data.frame(inventory, stringsAsFactors = FALSE)
  data.frame(
    path = as.character(inventory$path),
    type = as.character(inventory$type),
    sha256 = ifelse(is.na(inventory$sha256), "", as.character(inventory$sha256)),
    bytes = ifelse(is.na(inventory$bytes), -1, as.numeric(inventory$bytes)),
    link_target = ifelse(
      is.na(inventory$link_target),
      "",
      as.character(inventory$link_target)
    ),
    stringsAsFactors = FALSE
  )
}

nav_inventories_identical <- function(first, second) {
  identical(nav_inventory_signature(first), nav_inventory_signature(second))
}

nav_collect_protected_paths <- function(project_root, evidence_dir) {
  roots <- c(
    "artifacts",
    "audit/analyses",
    "audit/decisions",
    "audit/handoffs",
    "audit/hypotheses",
    "audit/ledgers",
    "audit/preparation_reports",
    "audit/reconciliation",
    "audit/report_harmonization",
    "config",
    "notebooks",
    "scripts",
    "tests"
  )
  paths <- unlist(lapply(roots, function(relative) {
    directory <- file.path(project_root, relative)
    if (!dir.exists(directory)) return(character())
    list.files(
      directory,
      recursive = TRUE,
      full.names = TRUE,
      all.files = TRUE,
      include.dirs = FALSE,
      no.. = TRUE
    )
  }), use.names = FALSE)
  root_files <- c(
    "_quarto-nathealth.yml",
    "_quarto.yml",
    "renv.lock",
    "bibliography.bib",
    "nature.csl",
    "styles.css",
    "styles-nathealth.css",
    "index.qmd",
    "supplementary_information.qmd",
    "_includes/nathealth-mobile-toc.html"
  )
  paths <- unique(c(paths, file.path(project_root, root_files)))
  normalized <- normalizePath(paths, winslash = "/", mustWork = FALSE)
  evidence_prefix <- paste0(
    normalizePath(evidence_dir, winslash = "/", mustWork = FALSE),
    "/"
  )
  paths[!startsWith(normalized, evidence_prefix)]
}

nav_extract_once <- function(text, pattern, label) {
  match <- regexpr(pattern, text, perl = TRUE)
  if (match[[1L]] < 0L) {
    stop("Could not find ", label, call. = FALSE)
  }
  matched <- regmatches(text, match)
  all_matches <- gregexpr(pattern, text, perl = TRUE)[[1L]]
  if (length(all_matches) != 1L || all_matches[[1L]] < 0L) {
    stop("Expected exactly one ", label, call. = FALSE)
  }
  matched
}

nav_replace_once <- function(text, pattern, replacement, label) {
  matches <- gregexpr(pattern, text, perl = TRUE)[[1L]]
  if (length(matches) != 1L || matches[[1L]] < 0L) {
    stop("Expected exactly one ", label, " for replacement", call. = FALSE)
  }
  start <- matches[[1L]]
  width <- attr(matches, "match.length")[[1L]]
  before <- if (start > 1L) substr(text, 1L, start - 1L) else ""
  after_start <- start + width
  after <- if (after_start <= nchar(text)) substring(text, after_start) else ""
  paste0(before, replacement, after)
}

nav_count_fixed <- function(text, token) {
  matches <- gregexpr(token, text, fixed = TRUE)[[1L]]
  if (length(matches) == 1L && matches[[1L]] < 0L) return(0L)
  as.integer(length(matches))
}

nav_replace_fixed_once <- function(text, token, replacement, label) {
  count <- nav_count_fixed(text, token)
  if (count != 1L) {
    stop(
      "Expected exactly one ", label, " for fixed-token replacement; found ",
      count,
      call. = FALSE
    )
  }
  sub(token, replacement, text, fixed = TRUE)
}

nav_extract_header <- function(text) {
  nav_extract_once(
    text,
    "(?s)<header id=\"quarto-header\".*?</header>",
    "Quarto header"
  )
}

nav_extract_breadcrumb <- function(text) {
  nav_extract_once(
    text,
    paste0(
      "(?s)<nav class=\"quarto-page-breadcrumbs ",
      "quarto-title-breadcrumbs[^\"]*\".*?</nav>"
    ),
    "title breadcrumb"
  )
}

nav_extract_page_navigation <- function(text) {
  nav_extract_once(
    text,
    "(?s)<nav class=\"page-navigation[^\"]*\".*?</nav>",
    "page navigation"
  )
}

nav_extract_toc <- function(text) {
  nav_extract_once(
    text,
    "(?s)<nav id=\"TOC\".*?</nav>",
    "table of contents"
  )
}

nav_protected_main <- function(text) {
  main <- nav_extract_once(
    text,
    "(?s)<main[^>]*id=\"quarto-document-content\".*?</main>",
    "main document"
  )
  main <- sub("^<main[^>]*>", "<main>", main, perl = TRUE)
  main <- sub(
    "<div class=\"quarto-title-meta column-page-(?:right|left)\">",
    "<div class=\"quarto-title-meta\">",
    main,
    perl = TRUE
  )
  main <- sub(
    paste0(
      "(?s)<nav class=\"quarto-page-breadcrumbs ",
      "quarto-title-breadcrumbs[^\"]*\".*?</nav>"
    ),
    "",
    main,
    perl = TRUE
  )
  sub(
    "(?s)<nav class=\"page-navigation[^\"]*\".*?</nav>",
    "",
    main,
    perl = TRUE
  )
}

nav_html_route <- function(expected_html) {
  sub("^_build/nathealth/", "", expected_html)
}

nav_shell_source_from_route <- function(route) {
  if (identical(route, "index.html")) return("index.qmd")
  sub("\\.html$", ".qmd", route)
}

nav_parse_command_status <- function(output) {
  status <- attr(output, "status")
  if (is.null(status)) 0L else as.integer(status)
}
