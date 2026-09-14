#!/usr/bin/env Rscript

# Build a navigation-only candidate from a synthetic Markdown project and
# byte-range edits to copies of the accepted HTML. This script never renders a
# project research QMD and never writes to the accepted build.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

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
preflight_checks <- readr::read_csv(
  file.path(evidence_dir, "preflight_checks.csv"),
  show_col_types = FALSE
)
stopifnot(nrow(preflight_checks) == 7L, all(preflight_checks$pass))

manifest_path <- file.path(
  project_root,
  "audit/report_harmonization/phase4_corpus_manifest.csv"
)
stopifnot(
  nav_sha256_file(manifest_path) == unname(nav_pinned_identities[[
    "audit/report_harmonization/phase4_corpus_manifest.csv"
  ]])
)
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
stopifnot(nrow(manifest) == 37L, !anyDuplicated(manifest$expected_html))

accepted_inventory <- nav_inventory_tree(file.path(project_root, "_build/nathealth"))
pre_inventory <- readr::read_csv(
  file.path(evidence_dir, "build_inventory_pre.csv"),
  show_col_types = FALSE
)
stopifnot(nav_inventories_identical(accepted_inventory, pre_inventory))

candidate_root <- tempfile(
  "nathealth-navigation-integration-",
  tmpdir = "/private/tmp"
)
dir.create(candidate_root, recursive = TRUE, showWarnings = FALSE)
candidate_root <- normalizePath(candidate_root, winslash = "/", mustWork = TRUE)
candidate_build <- file.path(candidate_root, "candidate_build")
shell_root <- file.path(candidate_root, "synthetic_shell")
dir.create(candidate_build, recursive = TRUE, showWarnings = FALSE)
dir.create(shell_root, recursive = TRUE, showWarnings = FALSE)

# Clone the accepted build from its sealed preflight inventory.
directory_rows <- pre_inventory[pre_inventory$type == "directory", , drop = FALSE]
directory_rows <- directory_rows[order(nchar(directory_rows$path)), , drop = FALSE]
for (relative in directory_rows$path) {
  dir.create(file.path(candidate_build, relative), recursive = TRUE, showWarnings = FALSE)
}
file_rows <- pre_inventory[pre_inventory$type == "file", , drop = FALSE]
for (relative in file_rows$path) {
  source_path <- file.path(project_root, "_build/nathealth", relative)
  target_path <- file.path(candidate_build, relative)
  nav_copy_file_exact(source_path, target_path)
}
cloned_inventory <- nav_inventory_tree(candidate_build)
stopifnot(nav_inventories_identical(cloned_inventory, pre_inventory))

# The base synthetic configuration contains only the website settings needed
# for Quarto to resolve navbar fragments. There are no manuscript resources,
# engines, filters, scientific inputs, or project source paths.
base_config <- paste0(
  "project:\n",
  "  type: website\n\n",
  "website:\n",
  "  title: \"Synthetic navigation shell\"\n",
  "  site-url: https://tscnlab.github.io/ZaunerEtAl_bioRxiv_2026\n",
  "  repo-url: https://github.com/tscnlab/ZaunerEtAl_bioRxiv_2026/\n",
  "  issue-url: https://github.com/tscnlab/ZaunerEtAl_bioRxiv_2026/issues\n",
  "  repo-actions: [edit, issue]\n",
  "  page-navigation: true\n",
  "  bread-crumbs: true\n\n",
  "format:\n",
  "  html:\n",
  "    theme:\n",
  "      - cosmo\n",
  "      - brand\n",
  "    css: styles.css\n",
  "    html-math-method: katex\n",
  "    link-external-newwindow: true\n",
  "    toc: true\n",
  "    code-link: true\n",
  "    code-line-numbers: true\n",
  "    toc-location: left\n",
  "    toc-depth: 3\n",
  "    toc-expand: 2\n\n",
  "format-links:\n",
  "  - html\n\n",
  "language:\n",
  "  title-block-published: \"Last modified:\"\n\n",
  "execute:\n",
  "  enabled: false\n"
)
nav_write_text_atomic(base_config, file.path(shell_root, "_quarto.yml"))

profile_lines <- readLines(
  file.path(project_root, "_quarto-nathealth.yml"),
  warn = FALSE,
  encoding = "UTF-8"
)
profile_lines <- profile_lines[
  !grepl("^  execute-dir:\\s*", profile_lines, perl = TRUE) &
    !grepl("^  post-render:\\s*", profile_lines, perl = TRUE)
]
execute_start <- grep("^execute:\\s*$", profile_lines, perl = TRUE)
format_start <- grep("^format:\\s*$", profile_lines, perl = TRUE)
stopifnot(length(execute_start) == 1L, length(format_start) == 1L)
stopifnot(execute_start < format_start)
profile_lines <- c(
  profile_lines[seq_len(execute_start - 1L)],
  "execute:",
  "  enabled: false",
  "",
  profile_lines[seq.int(format_start, length(profile_lines))]
)
profile_text <- paste0(profile_lines, collapse = "\n")
stopifnot(
  !grepl("post-render", profile_text, fixed = TRUE),
  !grepl("execute-dir", profile_text, fixed = TRUE),
  grepl("enabled: false", profile_text, fixed = TRUE),
  !grepl(project_root, profile_text, fixed = TRUE)
)
nav_write_text_atomic(
  paste0(profile_text, "\n"),
  file.path(shell_root, "_quarto-nathealth.yml")
)

for (relative in c(
  "styles.css",
  "styles-nathealth.css",
  "_includes/nathealth-mobile-toc.html",
  "LICENSE.md"
)) {
  nav_copy_file_exact(
    file.path(project_root, relative),
    file.path(shell_root, relative)
  )
}

yaml_quote <- function(value) {
  paste0(
    "\"",
    gsub("\"", "\\\\\"", value, fixed = TRUE),
    "\""
  )
}

routes <- vapply(manifest$expected_html, nav_html_route, character(1))
shell_sources <- vapply(routes, nav_shell_source_from_route, character(1))
for (index in seq_along(shell_sources)) {
  source_path <- file.path(shell_root, shell_sources[[index]])
  title <- manifest$title[[index]]
  dummy <- paste0(
    "---\n",
    "title: ", yaml_quote(title), "\n",
    "---\n\n",
    "## Navigation shell marker {#navigation-shell-marker}\n\n",
    "Synthetic structure only.\n"
  )
  nav_write_text_atomic(dummy, source_path)
}

shell_qmd <- sort(list.files(
  shell_root,
  pattern = "\\.qmd$",
  recursive = TRUE,
  full.names = TRUE
))
shell_text <- vapply(shell_qmd, nav_read_text, character(1))
stopifnot(
  length(shell_qmd) == 37L,
  all(grepl("Navigation shell marker", shell_text, fixed = TRUE)),
  !any(grepl("```", shell_text, fixed = TRUE)),
  !any(grepl("\\{r[ ,}]", shell_text, perl = TRUE)),
  !any(grepl("engine:", shell_text, fixed = TRUE)),
  !any(grepl(project_root, shell_text, fixed = TRUE)),
  !any(nzchar(Sys.readlink(shell_qmd)))
)

shell_scan <- data.frame(
  path = vapply(shell_qmd, nav_relative_to, character(1), root = shell_root),
  sha256 = vapply(shell_qmd, nav_sha256_file, character(1)),
  bytes = vapply(shell_qmd, nav_file_bytes, numeric(1)),
  synthetic_marker = vapply(
    shell_text,
    grepl,
    logical(1),
    pattern = "Navigation shell marker",
    fixed = TRUE
  ),
  stringsAsFactors = FALSE
)
readr::write_csv(
  shell_scan,
  file.path(evidence_dir, "synthetic_shell_sources.csv")
)

old_working_directory <- getwd()
setwd(shell_root)
render_output <- suppressWarnings(system2(
  "quarto",
  c("render", "--profile", "nathealth"),
  stdout = TRUE,
  stderr = TRUE,
  env = c(
    "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
    "QUARTO_R=/usr/bin/false"
  )
))
setwd(old_working_directory)
render_status <- nav_parse_command_status(render_output)
writeLines(
  enc2utf8(render_output),
  file.path(evidence_dir, "synthetic_shell_render.txt"),
  useBytes = TRUE
)
stopifnot(render_status == 0L)

shell_build <- file.path(shell_root, "_build/nathealth")
shell_html <- sort(list.files(
  shell_build,
  pattern = "\\.html$",
  recursive = TRUE,
  full.names = TRUE
))
shell_routes <- vapply(shell_html, nav_relative_to, character(1), root = shell_build)
stopifnot(length(shell_routes) == 37L, setequal(shell_routes, routes))

# The approved preview established the exact two Bootstrap variants. They are
# copied only into the candidate after their sealed hashes and sizes pass.
approved_preview_build <- normalizePath(
  Sys.getenv(
    "NATHEALTH_APPROVED_PREVIEW_BUILD",
    unset = paste0(
      "/private/tmp/nathealth-navigation-render.AiufEE/project/",
      "_build/nathealth"
    )
  ),
  winslash = "/",
  mustWork = TRUE
)
approved_preview_assets <- file.path(
  approved_preview_build,
  names(nav_candidate_asset_hashes)[-1L]
)
approved_preview_audit <- data.frame(
  path = names(nav_candidate_asset_hashes)[-1L],
  expected_sha256 = unname(nav_candidate_asset_hashes[-1L]),
  live_sha256 = vapply(approved_preview_assets, nav_sha256_file, character(1)),
  expected_bytes = unname(nav_candidate_asset_bytes[-1L]),
  live_bytes = vapply(approved_preview_assets, nav_file_bytes, numeric(1)),
  stringsAsFactors = FALSE
)
approved_preview_audit$exact <-
  approved_preview_audit$expected_sha256 == approved_preview_audit$live_sha256 &
  approved_preview_audit$expected_bytes == approved_preview_audit$live_bytes
readr::write_csv(
  approved_preview_audit,
  file.path(evidence_dir, "approved_preview_asset_identities.csv")
)
stopifnot(all(approved_preview_audit$exact))

nav_copy_file_exact(
  file.path(project_root, "styles-nathealth.css"),
  file.path(candidate_build, "styles-nathealth.css")
)
for (index in seq_along(approved_preview_assets)) {
  nav_copy_file_exact(
    approved_preview_assets[[index]],
    file.path(candidate_build, approved_preview_audit$path[[index]])
  )
}

mobile_script <- nav_read_text(
  file.path(project_root, "_includes/nathealth-mobile-toc.html")
)
layout_class_exempt_routes <- c(
  "index.html",
  "notebooks/hypotheses/H06_daily.html",
  "notebooks/hypotheses/H07.html"
)
main_layout_right <- paste0(
  "<main class=\"content column-page-right\" ",
  "id=\"quarto-document-content\">"
)
main_layout_left <- paste0(
  "<main class=\"content column-page-left\" ",
  "id=\"quarto-document-content\">"
)
title_meta_layout_right <-
  "<div class=\"quarto-title-meta column-page-right\">"
title_meta_layout_left <-
  "<div class=\"quarto-title-meta column-page-left\">"
transform_rows <- list()
for (index in seq_len(nrow(manifest))) {
  route <- routes[[index]]
  accepted_path <- file.path(project_root, manifest$expected_html[[index]])
  candidate_path <- file.path(candidate_build, route)
  shell_path <- file.path(shell_build, route)
  accepted <- nav_read_text(accepted_path)
  shell <- nav_read_text(shell_path)

  accepted_toc <- nav_extract_toc(accepted)
  accepted_page_navigation <- nav_extract_page_navigation(accepted)
  accepted_protected_main <- nav_protected_main(accepted)
  shell_header <- nav_extract_header(shell)
  shell_breadcrumb <- tryCatch(
    nav_extract_breadcrumb(shell),
    error = function(error) NULL
  )
  shell_body <- nav_extract_once(
    shell,
    "<body class=\"[^\"]*\">",
    "shell body opening"
  )
  shell_content <- nav_extract_once(
    shell,
    "<div id=\"quarto-content\" class=\"[^\"]*\">",
    "shell content opening"
  )
  shell_bootstrap <- nav_extract_once(
    shell,
    paste0(
      "<link href=\"[^\"]*site_libs/bootstrap/",
      "bootstrap-[a-f0-9]+\\.min\\.css\"[^>]*id=\"quarto-bootstrap\"[^>]*>"
    ),
    "shell Bootstrap stylesheet"
  )
  desired_bootstrap <- if (identical(route, "index.html")) {
    "bootstrap-972c31c23100bce3c5dc8576c7cea842.min.css"
  } else {
    "bootstrap-1b8143a5af30aa0587ead8c64582f750.min.css"
  }
  shell_bootstrap <- sub(
    "bootstrap-[a-f0-9]+\\.min\\.css",
    desired_bootstrap,
    shell_bootstrap,
    perl = TRUE
  )
  shell_nathealth_css <- nav_extract_once(
    shell,
    "<link rel=\"stylesheet\" href=\"[^\"]*styles-nathealth\\.css\">",
    "Nature Health stylesheet"
  )

  candidate <- accepted
  candidate <- nav_replace_once(
    candidate,
    "<body class=\"[^\"]*\">",
    shell_body,
    "body opening"
  )
  candidate <- nav_replace_once(
    candidate,
    "(?s)<header id=\"quarto-header\".*?</header>",
    shell_header,
    "Quarto header"
  )
  candidate <- nav_replace_once(
    candidate,
    "<div id=\"quarto-content\" class=\"[^\"]*\">",
    shell_content,
    "Quarto content opening"
  )
  candidate <- nav_replace_once(
    candidate,
    "(?s)<!-- sidebar -->.*?<!-- margin-sidebar -->",
    "<!-- sidebar -->\n<!-- margin-sidebar -->",
    "old sidebar region"
  )
  margin <- paste0(
    "<!-- margin-sidebar -->\n",
    "    <div id=\"quarto-margin-sidebar\" class=\"sidebar margin-sidebar\">\n",
    "        ", accepted_toc, "\n",
    "    </div>\n",
    "<!-- main -->"
  )
  candidate <- nav_replace_once(
    candidate,
    "(?s)<!-- margin-sidebar -->.*?<!-- main -->",
    margin,
    "margin sidebar region"
  )
  if (is.null(shell_breadcrumb)) {
    stopifnot(route %in% c("index.html", "supplementary_information.html"))
    stopifnot(!grepl("quarto-title-breadcrumbs", candidate, fixed = TRUE))
  } else {
    candidate <- nav_replace_once(
      candidate,
      paste0(
        "(?s)<nav class=\"quarto-page-breadcrumbs ",
        "quarto-title-breadcrumbs[^\"]*\".*?</nav>"
      ),
      shell_breadcrumb,
      "title breadcrumb"
    )
  }

  main_right_before <- nav_count_fixed(candidate, main_layout_right)
  main_left_before <- nav_count_fixed(candidate, main_layout_left)
  title_meta_right_before <- nav_count_fixed(candidate, title_meta_layout_right)
  title_meta_left_before <- nav_count_fixed(candidate, title_meta_layout_left)
  layout_class_affected <- !route %in% layout_class_exempt_routes
  if (layout_class_affected) {
    stopifnot(
      main_right_before == 1L,
      main_left_before == 0L,
      title_meta_right_before == 1L,
      title_meta_left_before == 0L
    )
    candidate <- nav_replace_fixed_once(
      candidate,
      main_layout_right,
      main_layout_left,
      "main column-page-right class token"
    )
    candidate <- nav_replace_fixed_once(
      candidate,
      title_meta_layout_right,
      title_meta_layout_left,
      "title-meta column-page-right class token"
    )
  } else {
    stopifnot(
      main_right_before == 0L,
      main_left_before == 0L,
      title_meta_right_before == 0L,
      title_meta_left_before == 0L
    )
  }
  main_right_after <- nav_count_fixed(candidate, main_layout_right)
  main_left_after <- nav_count_fixed(candidate, main_layout_left)
  title_meta_right_after <- nav_count_fixed(candidate, title_meta_layout_right)
  title_meta_left_after <- nav_count_fixed(candidate, title_meta_layout_left)
  stopifnot(
    main_right_after == 0L,
    title_meta_right_after == 0L,
    main_left_after == as.integer(layout_class_affected),
    title_meta_left_after == as.integer(layout_class_affected)
  )
  candidate <- nav_replace_once(
    candidate,
    "<link href=\"[^\"]+\"[^>]*id=\"quarto-bootstrap\"[^>]*>",
    shell_bootstrap,
    "Bootstrap stylesheet"
  )
  if (!grepl("styles-nathealth.css", candidate, fixed = TRUE)) {
    styles_link <- tryCatch(
      nav_extract_once(
        candidate,
        "<link rel=\"stylesheet\" href=\"[^\"]*styles\\.css\">",
        "base stylesheet"
      ),
      error = function(error) NULL
    )
    if (is.null(styles_link)) {
      candidate <- nav_replace_once(
        candidate,
        "</head>(?=\\s*<body class=)",
        paste0(shell_nathealth_css, "\n</head>"),
        "document head closing tag"
      )
    } else {
      candidate <- sub(
        styles_link,
        paste0(styles_link, "\n", shell_nathealth_css),
        candidate,
        fixed = TRUE
      )
    }
  }
  stopifnot(!grepl("nathealth-mobile-toc", candidate, fixed = TRUE))
  candidate <- nav_replace_once(
    candidate,
    "</body>(?=\\s*</html>\\s*$)",
    paste0(mobile_script, "\n</body>"),
    "document body closing tag"
  )

  # The prior/next block and all visible main content outside the breadcrumb
  # must remain byte-identical in the candidate.
  stopifnot(
    identical(nav_extract_page_navigation(candidate), accepted_page_navigation),
    identical(nav_protected_main(candidate), accepted_protected_main)
  )
  nav_write_text_atomic(candidate, candidate_path)
  transform_rows[[length(transform_rows) + 1L]] <- data.frame(
    logical_order = manifest$logical_order[[index]],
    route = route,
    accepted_sha256 = nav_sha256_file(accepted_path),
    candidate_sha256 = nav_sha256_file(candidate_path),
    layout_class_affected = layout_class_affected,
    main_right_before = main_right_before,
    main_layout_replacements = as.integer(layout_class_affected),
    main_left_after = main_left_after,
    title_meta_right_before = title_meta_right_before,
    title_meta_layout_replacements = as.integer(layout_class_affected),
    title_meta_left_after = title_meta_left_after,
    protected_main_sha256 = paste0(openssl::sha256(charToRaw(accepted_protected_main))),
    page_navigation_sha256 = paste0(openssl::sha256(charToRaw(accepted_page_navigation))),
    stringsAsFactors = FALSE
  )
}

transform_manifest <- do.call(rbind, transform_rows)
stopifnot(
  nrow(transform_manifest) == 37L,
  sum(transform_manifest$layout_class_affected) == 34L,
  setequal(
    transform_manifest$route[transform_manifest$layout_class_affected],
    setdiff(routes, layout_class_exempt_routes)
  ),
  sum(transform_manifest$main_layout_replacements) == 34L,
  sum(transform_manifest$title_meta_layout_replacements) == 34L
)
readr::write_csv(
  transform_manifest,
  file.path(evidence_dir, "candidate_html_transitions.csv")
)

candidate_pointer <- paste0(candidate_root, "\n")
nav_write_text_atomic(
  candidate_pointer,
  file.path(evidence_dir, "candidate_root.txt")
)

cat(sprintf(
  paste0(
    "NAVIGATION_SHELL_CANDIDATE=BUILT routes=%d synthetic_qmd=%d ",
    "accepted_build_untouched=TRUE root=%s\n"
  ),
  nrow(transform_manifest),
  length(shell_qmd),
  candidate_root
))
