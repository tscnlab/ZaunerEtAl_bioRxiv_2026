#!/usr/bin/env Rscript

# Build the static preview assets used by the Nature Health figure/table
# selection document. This script extracts accepted rendered endpoints and
# assembles planning tables from frozen accepted result rows. It does not
# execute a Quarto source, fit a model, regenerate a scientific artifact, or
# calculate a new estimand.

suppressPackageStartupMessages({
  library(digest)
  library(xml2)
})

required_r <- "4.6.1"
if (!identical(as.character(getRversion()), required_r)) {
  stop("This structural inventory must run under R ", required_r, ".")
}

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(project_root)

asset_dir <- file.path(
  "audit",
  "manuscript_nature_health",
  "figure_table_selection_assets"
)
dir.create(asset_dir, recursive = TRUE, showWarnings = FALSE)

semantic_engine_path <-
  "scripts/report_harmonization/repair_gt_html_semantics.R"
semantic_engine <- new.env(parent = globalenv())
sys.source(semantic_engine_path, envir = semantic_engine)
semantic_wrapper_path <-
  "scripts/report_harmonization/post_render_gt_html_semantics.R"
semantic_wrapper <- new.env(parent = globalenv())
sys.source(semantic_wrapper_path, envir = semantic_wrapper)

sha256_file <- function(path) {
  if (!file.exists(path) || dir.exists(path)) {
    stop("Expected a regular file: ", path)
  }
  digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

file_bytes <- function(path) {
  as.numeric(file.info(path)$size)
}

selection_figure_inputs <- data.frame(
  path = c(
    paste0(
      "artifacts/10_figures/H03/",
      "H03_manuscript_supplementary_figure_S7.png"
    ),
    file.path(
      asset_dir,
      "H04_manuscript_figure3_selection_candidate.png"
    ),
    file.path(
      asset_dir,
      "H04_manuscript_figure3_selection_candidate.svg"
    ),
    file.path(
      asset_dir,
      "supplementary_figure_s6.png"
    ),
    file.path(
      asset_dir,
      "supplementary_figure_s6.svg"
    ),
    file.path(
      asset_dir,
      "supplementary_figure_s14.png"
    ),
    file.path(
      asset_dir,
      "supplementary_figure_s14.svg"
    ),
    file.path(
      asset_dir,
      "H10_age_site_significant_associations_selection_candidate.png"
    )
  ),
  expected_sha256 = c(
    "ae5174afa8d9b57b5d9a635dfe2320482105d72007882db7513e29380271f52d",
    "22d402974fc0df26c77536e5db8af166e87637f2192ea4cc4f01da2d98ebb122",
    "012453debcd7994ab8b8437bd1b829a4935b26d97803963c6621ee2093bd72dd",
    "84e3228b24228d251a95ab78535e6917800b791744bf8540546014a2f7c39fda",
    "2dde6fd681f21feecf2acb6d693679bc56f68f809691172bb755e7aac47fa032",
    "7ab6a8f685923d9e545a7b452d272307b5dedc5f98af8e5f22554b0eafbfb41e",
    "e4b1fe228897a7135bd017c7c01f80a796a43819d5c1078008f2a927093508b5",
    "e989646f21543203ef07916dde8917e85243667d54b5aa492815476edc6c4b60"
  ),
  stringsAsFactors = FALSE
)
selection_figure_observed_sha256 <- vapply(
  selection_figure_inputs$path,
  sha256_file,
  character(1)
)
if (!identical(
  unname(selection_figure_observed_sha256),
  selection_figure_inputs$expected_sha256
)) {
  bad <- selection_figure_inputs$path[
    selection_figure_observed_sha256 !=
      selection_figure_inputs$expected_sha256
  ]
  stop("An accepted selection figure identity changed: ", paste(bad, collapse = ", "))
}

brown_owner_root <- Sys.getenv(
  "BROWN_OWNER_WORKTREE",
  unset = paste0(
    "/Users/zauner/.codex/worktrees/82ab/",
    "ZaunerEtAl_bioRxiv_2026"
  )
)
brown_cross_window_source_path <- file.path(
  brown_owner_root,
  paste0(
    "audit/analyses/brown_adherence/stage3_cross_state_association/",
    "source_data/table_association_effects.csv"
  )
)
brown_copy_specs <- data.frame(
  source = file.path(
    brown_owner_root,
    c(
      paste0(
        "audit/analyses/brown_adherence/manuscript_selection/",
        "supplementary_figure_s4/daytime_typography_continuation/",
        "candidate/supplementary_figure_s4.svg"
      ),
      paste0(
        "audit/analyses/brown_adherence/manuscript_selection/",
        "supplementary_figure_s5/tag_size_18_continuation/final/",
        "supplementary_figure_s5.png"
      ),
      paste0(
        "audit/analyses/brown_adherence/manuscript_selection/",
        "supplementary_figure_s5/tag_size_18_continuation/final/",
        "supplementary_figure_s5.svg"
      )
    )
  ),
  destination = file.path(
    asset_dir,
    c(
      "brown_adherence_levels.svg",
      "brown_supplementary_figure_s5.png",
      "brown_supplementary_figure_s5.svg"
    )
  ),
  sha256 = c(
    "65c262ff90dbf458549a417d722e625fba5d30ed892edabd34e81c37b55c1433",
    "513d7dcb12dc99daf54a8b4bd495877bec68824282167313e57de6d06cfe8a27",
    "61e8d4671939659ecf5eca6c6688c03414bb849d15b9d3f59f39c96ca7069cfd"
  ),
  status = c(
    "owner-sealed Brown Supplementary Figure S4 Daytime and typography continuation",
    "owner-sealed Brown Supplementary Figure S5 raster composite",
    "owner-sealed Brown Supplementary Figure S5 vector composite"
  ),
  stringsAsFactors = FALSE
)
for (index in seq_len(nrow(brown_copy_specs))) {
  source <- brown_copy_specs$source[[index]]
  destination <- brown_copy_specs$destination[[index]]
  expected <- brown_copy_specs$sha256[[index]]
  if (file.exists(source) && identical(sha256_file(source), expected)) {
    if (!file.copy(source, destination, overwrite = TRUE, copy.mode = TRUE)) {
      stop("Could not refresh the Brown planning copy: ", destination)
    }
  }
  if (
    !file.exists(destination) || !identical(sha256_file(destination), expected)
  ) {
    stop(
      "The Brown planning copy is unavailable or has changed: ",
      destination
    )
  }
}

normalize_caption <- function(text) {
  text <- gsub("\u00a0", " ", text, fixed = TRUE)
  text <- gsub("[[:space:]]+", " ", text)
  trimws(text)
}

semantic_summaries <- list()
semantic_ledgers <- list()

html_escape <- function(text) {
  text <- gsub("&", "&amp;", as.character(text), fixed = TRUE)
  text <- gsub("<", "&lt;", text, fixed = TRUE)
  text <- gsub(">", "&gt;", text, fixed = TRUE)
  text <- gsub('"', "&quot;", text, fixed = TRUE)
  text
}

strip_layout_classes <- function(node) {
  class_nodes <- xml_find_all(node, ".//*[@class] | self::*[@class]")
  for (class_node in class_nodes) {
    classes <- strsplit(xml_attr(class_node, "class"), "[[:space:]]+")[[1]]
    classes <- classes[
      !classes %in%
        c(
          "column-page",
          "column-screen",
          "column-screen-inset",
          "page-columns",
          "page-full"
        )
    ]
    if (length(classes)) {
      xml_set_attr(class_node, "class", paste(classes, collapse = " "))
    } else {
      xml_attr(class_node, "class") <- NULL
    }
  }
  invisible(node)
}

remove_raw_p_from_h05 <- function(node) {
  small_nodes <- xml_find_all(node, ".//small[contains(., 'Raw p =')]")
  for (small_node in small_nodes) {
    cleaned <- sub(
      "^Raw p = [^;]+;[[:space:]]*",
      "",
      normalize_caption(xml_text(small_node))
    )
    if (!startsWith(cleaned, "FDR-adjusted p =")) {
      stop(
        "Could not remove an H05 raw p-value without changing its FDR value."
      )
    }
    xml_text(small_node) <- cleaned
  }
  invisible(node)
}

remove_raw_p_from_source_note <- function(node) {
  notes <- xml_find_all(
    node,
    ".//*[contains(concat(' ', @class, ' '), ' gt_sourcenote ')]"
  )
  for (note in notes) {
    value <- normalize_caption(xml_text(note))
    value <- sub(
      "Raw p has no separate bolding rule; ",
      "",
      value,
      fixed = TRUE
    )
    value <- sub(
      paste0(
        "Raw p-values are bold when raw p < 0.050; ",
        "adjusted p-values"
      ),
      "FDR-adjusted p-values",
      value,
      fixed = TRUE
    )
    xml_text(note) <- value
  }
  invisible(node)
}

drop_gt_column_by_label <- function(node, label) {
  headers <- xml_find_all(node, ".//thead//th")
  labels <- vapply(
    headers,
    function(header) {
      normalize_caption(xml_text(header))
    },
    character(1)
  )
  target <- headers[labels == label]
  if (length(target) != 1L) {
    stop("Expected one gt column labelled '", label, "'.")
  }
  target_id <- xml_attr(target[[1]], "id")
  target_position <- length(xml_find_all(
    target[[1]],
    "preceding-sibling::th | preceding-sibling::td"
  )) +
    1L

  data_cells <- xml_find_all(node, ".//tbody/*/*[@headers]")
  target_cells <- data_cells[vapply(
    data_cells,
    function(cell) {
      tokens <- strsplit(xml_attr(cell, "headers"), "[[:space:]]+")[[1]]
      target_id %in% tokens
    },
    logical(1)
  )]
  if (!length(target_cells)) {
    stop("The requested gt column has no body cells: ", label)
  }
  xml_remove(target_cells)
  xml_remove(target[[1]])

  colgroups <- xml_find_all(node, ".//colgroup")
  for (colgroup in colgroups) {
    columns <- xml_children(colgroup)
    if (length(columns) >= target_position) {
      xml_remove(columns[[target_position]])
    }
  }

  table <- xml_find_first(
    node,
    ".//table[contains(concat(' ', @class, ' '), ' gt_table ')]"
  )
  id_nodes <- xml_find_all(table, "self::*[@id] | .//*[@id]")
  old_ids <- xml_attr(id_nodes, "id")
  endpoint <- sub("--gt-[0-9]{4}$", "", target_id, perl = TRUE)
  if (
    inherits(table, "xml_missing") ||
      !length(old_ids) ||
      anyNA(old_ids) ||
      anyDuplicated(old_ids) ||
      !nzchar(endpoint)
  ) {
    stop("Could not renumber the reduced gt table after dropping ", label, ".")
  }
  new_ids <- sprintf("%s--gt-%04d", endpoint, seq_along(old_ids))
  names(new_ids) <- old_ids
  header_nodes <- xml_find_all(table, "self::*[@headers] | .//*[@headers]")
  for (header_node in header_nodes) {
    tokens <- strsplit(xml_attr(header_node, "headers"), "[[:space:]]+")[[1]]
    mapped <- unname(new_ids[tokens])
    if (!length(tokens) || anyNA(mapped)) {
      stop("A reduced gt table contains an unresolved headers token.")
    }
    xml_set_attr(header_node, "headers", paste(mapped, collapse = " "))
  }
  for (index in seq_along(id_nodes)) {
    xml_set_attr(id_nodes[[index]], "id", new_ids[[index]])
  }
  invisible(node)
}

prepare_table_display <- function(display, endpoint) {
  clone_document <- read_html(paste0(
    "<html><body>",
    as.character(display[[1]]),
    "</body></html>"
  ))
  clone <- xml_find_first(clone_document, "//body/*[1]")
  if (inherits(clone, "xml_missing")) {
    stop("Could not clone the table display for ", endpoint, ".")
  }
  strip_layout_classes(clone)
  if (endpoint %in% c("tbl-h05-near-results-a", "tbl-h05-near-results-b")) {
    remove_raw_p_from_h05(clone)
  }
  if (
    endpoint %in%
      c(
        "tbl-h08-near-eye-results",
        "tbl-h09-near-eye-results",
        "tbl-h10-main-results"
      )
  ) {
    drop_gt_column_by_label(clone, "Raw p")
  }
  if (
    endpoint %in%
      c(
        "tbl-h05-near-results-a",
        "tbl-h05-near-results-b",
        "tbl-h08-near-eye-results",
        "tbl-h09-near-eye-results",
        "tbl-h10-main-results"
      )
  ) {
    remove_raw_p_from_source_note(clone)
  }
  clone
}

build_semantic_table_fragment <- function(display, endpoint, source_html) {
  input_path <- tempfile("table-preview-pre-", fileext = ".html")
  output_path <- tempfile("table-preview-post-", fileext = ".html")
  ledger_path <- tempfile("table-preview-ledger-", fileext = ".csv")
  on.exit(unlink(c(input_path, output_path, ledger_path)), add = TRUE)

  prepared_display <- prepare_table_display(display, endpoint)
  pre_fragment <- paste0(
    "<div id=\"",
    endpoint,
    "\" class=\"accepted-table-preview\" data-source-endpoint=\"",
    endpoint,
    "\">\n",
    as.character(prepared_display),
    "\n</div>\n"
  )
  writeLines(pre_fragment, input_path, useBytes = TRUE)

  state <- tryCatch(
    semantic_wrapper$inspect_gt_html_state(input_path, semantic_engine),
    error = function(condition) {
      stop(
        "Semantic inspection failed for ",
        endpoint,
        ": ",
        conditionMessage(condition),
        call. = FALSE
      )
    }
  )
  repair <- if (identical(state$disposition, "ALREADY_REPAIRED")) {
    file.copy(input_path, output_path, overwrite = FALSE)
    list(
      disposition = "ALREADY_REPAIRED",
      input_sha256 = state$sha256,
      output_sha256 = state$sha256,
      reversed_sha256 = state$sha256,
      input_bytes = state$bytes,
      output_bytes = state$bytes,
      table_count = state$table_count,
      id_substitutions = 0L,
      headers_substitutions = 0L,
      total_substitutions = 0L,
      unsupported_id_references = 0L
    )
  } else {
    repaired <- tryCatch(
      semantic_engine$repair_gt_html_semantics(
        input_path,
        output_path,
        ledger_path
      ),
      error = function(condition) {
        stop(
          "Semantic repair failed for ",
          endpoint,
          ": ",
          conditionMessage(condition),
          call. = FALSE
        )
      }
    )
    repaired$disposition <- "REPAIRED"
    repaired
  }
  repaired_raw <- readBin(
    output_path,
    what = "raw",
    n = as.numeric(file.info(output_path)$size)
  )
  repaired_fragment <- rawToChar(repaired_raw)

  if (file.exists(ledger_path)) {
    ledger <- read.csv(
      ledger_path,
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
    ledger$preview_endpoint <- endpoint
    ledger$source_html <- source_html
    semantic_ledgers[[length(semantic_ledgers) + 1L]] <<- ledger
  }
  semantic_summaries[[length(semantic_summaries) + 1L]] <<- data.frame(
    preview_endpoint = endpoint,
    source_html = source_html,
    disposition = repair$disposition,
    pre_sha256 = repair$input_sha256,
    post_sha256 = repair$output_sha256,
    reversed_sha256 = repair$reversed_sha256,
    pre_bytes = repair$input_bytes,
    post_bytes = repair$output_bytes,
    table_count = repair$table_count,
    id_substitutions = repair$id_substitutions,
    headers_substitutions = repair$headers_substitutions,
    total_substitutions = repair$total_substitutions,
    unsupported_id_references = repair$unsupported_id_references,
    stringsAsFactors = FALSE
  )

  paste0(
    "<!-- Static accepted table preview extracted from ",
    source_html,
    "#",
    endpoint,
    "; only gt-internal id and headers values are namespaced. -->\n",
    "```{=html}\n",
    repaired_fragment,
    "```\n"
  )
}

catalog <- data.frame(
  analysis = c(
    "Descriptives",
    "H01",
    "H02",
    "H03",
    "H04",
    "H05",
    "H06",
    "H06_daily",
    "H07",
    "H08",
    "H09",
    "H10",
    "H11"
  ),
  reader_html = c(
    "_build/nathealth/notebooks/descriptives.html",
    "_build/nathealth/notebooks/hypotheses/H01.html",
    "_build/nathealth/notebooks/hypotheses/H02.html",
    "_build/nathealth/notebooks/hypotheses/H03.html",
    "_build/nathealth/notebooks/hypotheses/H04.html",
    "_build/nathealth/notebooks/hypotheses/H05.html",
    "_build/nathealth/notebooks/hypotheses/H06.html",
    "_build/nathealth/notebooks/hypotheses/H06_daily.html",
    "_build/nathealth/notebooks/hypotheses/H07.html",
    "_build/nathealth/notebooks/hypotheses/H08.html",
    "_build/nathealth/notebooks/hypotheses/H09.html",
    "_build/nathealth/notebooks/hypotheses/H10.html",
    "_build/nathealth/notebooks/hypotheses/H11.html"
  ),
  table_id = c(
    "tbl-participant-site-manuscript",
    "tbl-h01-primary-publication-summary",
    "tbl-h02-near-variation",
    "tbl-h03-near-site-factorization",
    "tbl-h04-near-site-factorization",
    "tbl-h05-near-results-a",
    "tbl-h06-primary-effects",
    "tbl-h06-daily-primary-matrix",
    "tbl-h07-near-results",
    "tbl-h08-near-eye-results",
    "tbl-h09-near-eye-results",
    "tbl-h10-main-results",
    "tbl-h11-global-tests"
  ),
  table_continuation_id = c(
    "",
    "",
    "",
    "",
    "",
    "tbl-h05-near-results-b",
    "",
    "",
    "",
    "",
    "",
    "",
    ""
  ),
  figure_id = c(
    "fig-descriptive-overview",
    "fig-h01-model-support",
    "fig-h02-near-patterns",
    "fig-h03-primary-estimates",
    "fig-h04-primary-estimates",
    "fig-h05-near-effects",
    "fig-h06-paired-placement",
    "fig-h06-daily-fdr-overview",
    "fig-h07-near-smooth-derivative-pairs",
    "fig-h08-near-eye-effects",
    "fig-h09-primary-effects",
    "fig-h10-age-site-overview",
    "fig-h11-near-eye-curves"
  ),
  figure_artifact = c(
    "artifacts/10_figures/descriptives/descriptive_overview.png",
    "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png",
    "artifacts/10_figures/H02/figure4_exact_layout_replication.png",
    "artifacts/10_figures/H03/H03_reader_heterogeneity_category_estimates.png",
    "artifacts/10_figures/H04/H04_reader_heterogeneity_category_estimates.png",
    "artifacts/10_figures/H05/H05_reader_near_eye_effects.png",
    "artifacts/10_figures/H06/H06_paired_placement_effects.png",
    paste0(
      "audit/hypotheses/H06_daily/",
      "manuscript_selection_supplementary_figure_s12/",
      "H06_daily_supplementary_figure_s12.svg"
    ),
    "artifacts/08_figures/H07/H07_revised_smooth_derivative_pairs_near_eye.png",
    "artifacts/10_figures/H08/H08_near_eye_effects.png",
    "artifacts/10_figures/H09/H09_primary_effects.png",
    "artifacts/10_figures/H10/H10_age_site_significant_associations.png",
    "artifacts/10_figures/H11/stage3/H11_reader_primary_near_eye_curves.png"
  ),
  stringsAsFactors = FALSE
)

phase4_path <- "audit/report_harmonization/phase4_corpus_manifest.csv"
phase4 <- read.csv(phase4_path, check.names = FALSE, stringsAsFactors = FALSE)
required_phase4 <- c("source", "source_sha256", "expected_html", "html_sha256")
if (!all(required_phase4 %in% names(phase4))) {
  stop("The phase 4 corpus manifest does not have the required columns.")
}

records <- vector("list", nrow(catalog))
h09_source_ready_sha256 <-
  "9db9671d61b39a81fa83b234e08832cef516ee91688ac8bc4150385629648df9"
h01_definition_aligned_sha256 <-
  "5e0bcf315ea113543dbcb762aaea19e4e2b0cd4bbe4f3520de04ebc19e041208"
h01_definition_aligned_html_sha256 <-
  "72458413f3a2b025474abdff556feeb897e4a968a254e2f546565348f8a07e4a"
source_postimages <- c(
  Descriptives = "c17fef3ca932fa8cf195f6ae6604e822e3b46235cefd6a081d4eef69b88546bc",
  H01 = "4618b80ed84518d94b8e8fe8b80db1fc43d272c2781c5294b3cc48b019348d43",
  H02 = "b50b55eebb75f120928707821dc3b8e8d6f16905418c56d8d689744926ff3de8",
  H03 = "27c1fea54e5f32570613df80768d1fb5b668f3033aee90069820e951001c2513",
  H04 = "243896d4c22f68d23027f77f3721882e0a3d55274e67014e75d6ff55e2e243af",
  H05 = "f748873f5f68198665fc3cb3d7047f586c619408f86e5e22bd9814593f9f2780",
  H06 = "013496ae4ac5db1e069af98bea87af6c202714ed97d40cf1f7f64e6637239f5a",
  H06_daily = "ddf7e8af287831b80243b4d35e83546fa6ee8f7f3794c9874d4712648b3eb2e7",
  H07 = "c2d24ee7199fc8399e7edfa1192a21de7c31bd7854a89d356386c5e669ff55ca",
  H08 = "56cdd3382ff933f20706d50e75af00160ebdc3c503307f9fdf02fb7c2ae6e859",
  H09 = "ae5b23d11e2c623b7150df7fe14292df4380e6417028630c30a30ae7dff1b34c",
  H10 = "0b2daad24e16ad62a87c2b74d5989cb2ff3738dca47d5dd3fda0af366e93c855",
  H11 = "a30520f117d65cf13b0cd87fce56395307582c9dfefa1b016332c6a695b80fb5"
)

for (index in seq_len(nrow(catalog))) {
  item <- catalog[index, , drop = FALSE]
  html_path <- item$reader_html[[1]]
  table_id <- item$table_id[[1]]
  table_continuation_id <- item$table_continuation_id[[1]]
  figure_id <- item$figure_id[[1]]
  figure_path <- item$figure_artifact[[1]]

  phase4_row <- phase4[phase4$expected_html == html_path, , drop = FALSE]
  if (nrow(phase4_row) != 1L) {
    stop("Expected exactly one phase 4 row for ", html_path, ".")
  }
  current_html_sha256 <- sha256_file(html_path)
  html_is_accepted <- identical(
    current_html_sha256,
    phase4_row$html_sha256[[1]]
  ) ||
    (identical(item$analysis[[1]], "H01") &&
      identical(current_html_sha256, h01_definition_aligned_html_sha256))
  if (!html_is_accepted) {
    stop(
      "Reader HTML does not match the accepted phase 4 identity: ",
      html_path
    )
  }
  source_path <- phase4_row$source[[1]]
  current_source_sha256 <- sha256_file(source_path)
  source_identity_status <- if (
    identical(current_source_sha256, phase4_row$source_sha256[[1]])
  ) {
    "REPORT-018 accepted source"
  } else if (
    identical(item$analysis[[1]], "H01") &&
      identical(current_source_sha256, h01_definition_aligned_sha256)
  ) {
    paste0(
      "Accepted H01 definition-aligned MDER source transition; accepted ",
      "HTML is independently accepted with the same integration"
    )
  } else if (
    identical(item$analysis[[1]], "H09") &&
      identical(current_source_sha256, h09_source_ready_sha256)
  ) {
    paste0(
      "Owner-verified H09 source-ready transition; accepted HTML remains ",
      "REPORT-018 exact"
    )
  } else if (
    item$analysis[[1]] %in% names(source_postimages) &&
      identical(
        current_source_sha256,
        source_postimages[[item$analysis[[1]]]]
      )
  ) {
    paste0(
      "Owner-verified table-harmonization source postimage; accepted ",
      "reader HTML remains pinned"
    )
  } else {
    stop(
      "Reader source has an unclassified transition: ",
      source_path
    )
  }

  document <- read_html(html_path)
  table_endpoint <- xml_find_all(
    document,
    paste0("//*[@id=\"", table_id, "\"]")
  )
  figure_endpoint <- xml_find_all(
    document,
    paste0("//*[@id=\"", figure_id, "\"]")
  )
  if (length(table_endpoint) != 1L) {
    stop("Expected one table endpoint ", table_id, " in ", html_path, ".")
  }
  if (length(figure_endpoint) != 1L) {
    stop("Expected one figure endpoint ", figure_id, " in ", html_path, ".")
  }

  table_display <- xml_find_all(
    table_endpoint,
    ".//*[contains(concat(' ', normalize-space(@class), ' '), ' cell-output-display ')]"
  )
  if (length(table_display) != 1L) {
    stop("Expected one visible table body for ", table_id, ".")
  }
  if (length(xml_find_all(table_display, ".//table")) != 1L) {
    stop("Expected one native table in ", table_id, ".")
  }

  table_caption_node <- xml_find_first(table_endpoint, ".//figcaption")
  figure_caption_node <- xml_find_first(figure_endpoint, ".//figcaption")
  figure_image_node <- xml_find_first(figure_endpoint, ".//img")
  if (
    inherits(table_caption_node, "xml_missing") ||
      inherits(figure_caption_node, "xml_missing") ||
      inherits(figure_image_node, "xml_missing")
  ) {
    stop("A required caption or image is missing for ", item$analysis[[1]], ".")
  }

  fragment_path <- file.path(asset_dir, paste0(table_id, ".html"))
  fragment <- build_semantic_table_fragment(
    table_display,
    table_id,
    html_path
  )
  if (identical(item$analysis[[1]], "H06_daily")) {
    old_note <- paste0(
      "Batch: primary near-eye predictor-specific participant-day models. ",
      "Each cell gives the estimate (pointwise 95% CI, not a simultaneous ",
      "interval), its 15-slot FDR q-value, and the exact fitted ",
      "participant-days and participants. Raw p-values and complete model ",
      "fields remain in the linked source CSV. Bold q-values meet the FDR ",
      "and claim-eligibility rule. All primary frames use nine sites."
    )
    accepted_note <- paste0(
      "Primary near-eye predictor-specific participant-day models. Each ",
      "cell gives the estimate with its 95% CI, FDR-adjusted q-value within ",
      "the 15-outcome family, and exact fitted participant-days and ",
      "participants. Bold q-values meet the FDR criterion. All analyses ",
      "use nine sites."
    )
    if (!grepl(old_note, fragment, fixed = TRUE)) {
      stop("The pinned H06_daily source note changed before replacement.")
    }
    fragment <- sub(old_note, accepted_note, fragment, fixed = TRUE)
  }
  writeLines(fragment, fragment_path, useBytes = TRUE)

  continuation_caption <- ""
  continuation_fragment_path <- ""
  continuation_fragment_sha256 <- ""
  continuation_fragment_bytes <- NA_real_
  if (nzchar(table_continuation_id)) {
    continuation_endpoint <- xml_find_all(
      document,
      paste0("//*[@id=\"", table_continuation_id, "\"]")
    )
    if (length(continuation_endpoint) != 1L) {
      stop("Expected one continuation endpoint ", table_continuation_id, ".")
    }
    continuation_display <- xml_find_all(
      continuation_endpoint,
      ".//*[contains(concat(' ', normalize-space(@class), ' '), ' cell-output-display ')]"
    )
    if (
      length(continuation_display) != 1L ||
        length(xml_find_all(continuation_display, ".//table")) != 1L
    ) {
      stop(
        "Expected one visible continuation table body for ",
        table_continuation_id,
        "."
      )
    }
    continuation_caption_node <- xml_find_first(
      continuation_endpoint,
      ".//figcaption"
    )
    if (inherits(continuation_caption_node, "xml_missing")) {
      stop("Continuation caption is missing for ", table_continuation_id, ".")
    }
    continuation_fragment_path <- file.path(
      asset_dir,
      paste0(table_continuation_id, ".html")
    )
    continuation_fragment <- build_semantic_table_fragment(
      continuation_display,
      table_continuation_id,
      html_path
    )
    writeLines(
      continuation_fragment,
      continuation_fragment_path,
      useBytes = TRUE
    )
    continuation_caption <- normalize_caption(xml_text(
      continuation_caption_node
    ))
    continuation_fragment_sha256 <- sha256_file(continuation_fragment_path)
    continuation_fragment_bytes <- file_bytes(continuation_fragment_path)
  }

  records[[index]] <- data.frame(
    analysis = item$analysis[[1]],
    source_qmd = source_path,
    accepted_source_qmd_sha256 = phase4_row$source_sha256[[1]],
    current_source_qmd_sha256 = current_source_sha256,
    source_identity_status = source_identity_status,
    reader_html = html_path,
    reader_html_sha256 = current_html_sha256,
    table_id = table_id,
    accepted_table_caption = normalize_caption(xml_text(table_caption_node)),
    table_fragment = fragment_path,
    table_fragment_sha256 = sha256_file(fragment_path),
    table_fragment_bytes = file_bytes(fragment_path),
    table_continuation_id = table_continuation_id,
    accepted_table_continuation_caption = continuation_caption,
    table_continuation_fragment = continuation_fragment_path,
    table_continuation_fragment_sha256 = continuation_fragment_sha256,
    table_continuation_fragment_bytes = continuation_fragment_bytes,
    figure_id = figure_id,
    accepted_figure_caption = normalize_caption(xml_text(figure_caption_node)),
    accepted_figure_alt = normalize_caption(xml_attr(figure_image_node, "alt")),
    figure_artifact = figure_path,
    figure_artifact_sha256 = sha256_file(figure_path),
    figure_artifact_bytes = file_bytes(figure_path),
    stringsAsFactors = FALSE
  )
}

inventory <- do.call(rbind, records)
inventory$accepted_table_caption[inventory$analysis == "H11"] <-
  "Global complete-curve tests and separately prespecified sensitivity decisions."
h06_daily_index <- inventory$analysis == "H06_daily"
inventory$accepted_figure_alt[h06_daily_index] <- paste0(
  "False-discovery-rate decision overview for primary and ",
  "gap-timing-unaware participant-day associations, with six estimable ",
  "melanopic daylight efficacy ratio cells shown as not supported and ",
  "darkest-10-hour mean outcomes shown as non-estimable."
)
if (
  anyDuplicated(inventory$analysis) ||
    anyDuplicated(inventory$table_id) ||
    anyDuplicated(inventory$figure_id)
) {
  stop(
    "The accepted output inventory contains a duplicate analysis or endpoint."
  )
}

write_planning_table_fragment <- function(
  path,
  id,
  caption,
  headers,
  rows,
  groups,
  source_note
) {
  if (ncol(rows) != length(headers) || nrow(rows) != length(groups)) {
    stop("A planning table has inconsistent dimensions: ", id)
  }
  body <- character()
  previous_group <- ""
  for (row_index in seq_len(nrow(rows))) {
    group <- groups[[row_index]]
    if (nzchar(group) && !identical(group, previous_group)) {
      body <- c(
        body,
        paste0(
          '<tr class="planning-row-group"><th scope="rowgroup" colspan="',
          ncol(rows),
          '">',
          html_escape(group),
          "</th></tr>"
        )
      )
      previous_group <- group
    }
    cells <- vapply(
      seq_len(ncol(rows)),
      function(column_index) {
        tag <- if (column_index == 1L) "th" else "td"
        scope <- if (column_index == 1L) ' scope="row"' else ""
        paste0(
          "<",
          tag,
          scope,
          ">",
          rows[[row_index, column_index]],
          "</",
          tag,
          ">"
        )
      },
      character(1)
    )
    body <- c(body, paste0("<tr>", paste(cells, collapse = ""), "</tr>"))
  }
  header_html <- paste0(
    "<tr>",
    paste0("<th scope=\"col\">", html_escape(headers), "</th>", collapse = ""),
    "</tr>"
  )
  fragment <- c(
    paste0(
      "<!-- Planning table assembled from pinned accepted rows: ",
      id,
      " -->"
    ),
    "```{=html}",
    paste0(
      '<div id="',
      id,
      '" class="accepted-table-preview planning-generated-table">',
      '<table class="planning-data-table">',
      "<caption>",
      html_escape(caption),
      "</caption>",
      "<thead>",
      header_html,
      "</thead>",
      "<tbody>",
      paste(body, collapse = "\n"),
      "</tbody>",
      "</table>",
      '<p class="planning-table-note">',
      source_note,
      "</p>",
      "</div>"
    ),
    "```"
  )
  writeLines(fragment, path, useBytes = TRUE)
  invisible(path)
}

normalize_gt_group_header_ids <- function(document, endpoint) {
  group_headers <- xml_find_all(
    document,
    paste0(
      "//tr[contains(concat(' ', normalize-space(@class), ' '), ",
      "' gt_group_heading_row ')]/th[contains(concat(' ', ",
      "normalize-space(@class), ' '), ' gt_group_heading ')]"
    )
  )
  if (!length(group_headers)) {
    return(document)
  }

  all_id_nodes <- xml_find_all(document, "//*[@id]")
  existing_ids <- xml_attr(all_id_nodes, "id")
  header_nodes <- xml_find_all(
    document,
    "//tbody//td[@headers] | //tbody//th[@headers]"
  )
  first_header_tokens <- vapply(
    xml_attr(header_nodes, "headers"),
    function(value) strsplit(trimws(value), "[[:space:]]+")[[1]][[1]],
    character(1)
  )
  missing_first_tokens <- unique(
    first_header_tokens[!first_header_tokens %in% existing_ids]
  )

  if (
    length(missing_first_tokens) != length(group_headers) ||
      anyNA(missing_first_tokens) ||
      any(!nzchar(missing_first_tokens)) ||
      anyDuplicated(missing_first_tokens)
  ) {
    stop(
      "Could not reconcile the gt row-group header IDs for ",
      endpoint,
      "."
    )
  }

  for (index in seq_along(group_headers)) {
    xml_set_attr(
      group_headers[[index]],
      "id",
      missing_first_tokens[[index]]
    )
  }

  repaired_ids <- xml_attr(xml_find_all(document, "//*[@id]"), "id")
  all_header_tokens <- unique(unlist(strsplit(
    xml_attr(header_nodes, "headers"),
    "[[:space:]]+"
  )))
  if (
    anyNA(repaired_ids) ||
      any(!nzchar(repaired_ids)) ||
      anyDuplicated(repaired_ids) ||
      !all(all_header_tokens %in% repaired_ids)
  ) {
    stop(
      "The normalized gt row-group semantics are invalid for ",
      endpoint,
      "."
    )
  }
  document
}

write_gt_table_fragment <- function(path, table, id) {
  raw_fragment <- gt::as_raw_html(table, inline_css = FALSE)
  source_document <- read_html(paste0(
    "<html><body><div class=\"cell-output-display\">",
    raw_fragment,
    "</div></body></html>"
  ))
  source_document <- normalize_gt_group_header_ids(source_document, id)
  display <- xml_find_all(
    source_document,
    "//div[contains(concat(' ', normalize-space(@class), ' '), ' cell-output-display ')]"
  )
  if (
    length(display) != 1L || length(xml_find_all(display, ".//table")) != 1L
  ) {
    stop("Could not construct one native gt display for ", id, ".")
  }
  writeLines(
    build_semantic_table_fragment(
      display,
      id,
      "generated from pinned accepted rows"
    ),
    path,
    useBytes = TRUE
  )
  invisible(path)
}

format_ci <- function(estimate, lower, upper, digits = 3L) {
  format_string <- paste0(
    "%.",
    digits,
    "f (%.",
    digits,
    "f to %.",
    digits,
    "f)"
  )
  sprintf(format_string, estimate, lower, upper)
}

format_percent_ci <- function(estimate, lower, upper) {
  sprintf(
    "%.1f%% (%.1f%% to %.1f%%)",
    100 * estimate,
    100 * lower,
    100 * upper
  )
}

one_row <- function(data, expression, label) {
  row <- data[
    eval(substitute(expression), data, parent.frame()),
    ,
    drop = FALSE
  ]
  if (nrow(row) != 1L) {
    stop("Expected one accepted row for ", label, "; found ", nrow(row), ".")
  }
  row
}

pinned_table_inputs <- c(
  "artifacts/09_tables/H02/variation_summary.csv" = "a07296c2e64e15a0217b9efc21b83acd578574f5b456a79eb2401382b0b4d3b0",
  "artifacts/09_tables/H02/dominance_summary.csv" = "c50589ee53541845cee1a104ae4aabb0bb45296a94e3ab7547fd1142ded4e84f",
  "artifacts/09_tables/H02/dominance_comparison_summary.csv" = "7240b7ab29818b085375a10c02bf53e49ad71203d6e2feb2385c590ca27e36fe",
  "artifacts/09_tables/H01/stage3/H01_stage3_primary_publication_summary.csv" = "38a3f76d72b433bc3ab97d4506e59f02d582887a5d853d58fd070ebf2279309e",
  "artifacts/09_tables/descriptives/metric_descriptive_summary_replica.csv" = "efd808cabcb90ca0d1254bf0195cc5ccb198a1d0d615037682bf8ed674d6a03b",
  "artifacts/09_tables/H01/stage3/H01_stage3_r2_table.csv" = "93a7b41482e0e0f7fd46b2c059335b326a2f966d31f6b6b52553a992fdd7ae4d",
  "audit/descriptives/sample_count_contract.csv" = "034e449164d617431e149b9ab28867ba4cc52830620e7acd606e756de61f1dd3"
)
pinned_table_inputs[[brown_cross_window_source_path]] <-
  "304eac7c2521ebeb1217dbfd6a2fc27ad07c74ebe00f75bfe026d1cff3ab10b9"
for (input_path in names(pinned_table_inputs)) {
  if (!identical(sha256_file(input_path), pinned_table_inputs[[input_path]])) {
    stop("A frozen planning-table input changed: ", input_path)
  }
}

h02_variation <- read.csv(
  "artifacts/09_tables/H02/variation_summary.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
h02_dominance <- read.csv(
  "artifacts/09_tables/H02/dominance_summary.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
h02_comparisons <- read.csv(
  "artifacts/09_tables/H02/dominance_comparison_summary.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

build_h02_merged_table <- function(placement, role, run_id, label) {
  variation <- h02_variation[h02_variation$run_id == run_id, , drop = FALSE]
  dominance <- h02_dominance[
    h02_dominance$placement == placement &
      h02_dominance$analytical_role == role,
    ,
    drop = FALSE
  ]
  comparisons <- h02_comparisons[
    h02_comparisons$placement == placement &
      h02_comparisons$analytical_role == role,
    ,
    drop = FALSE
  ]
  if (
    nrow(variation) != 6L || nrow(dominance) != 4L || nrow(comparisons) != 4L
  ) {
    stop("The accepted H02 rows are incomplete for ", placement, ".")
  }

  variation_value <- function(id) {
    row <- variation[variation$summary_id == id, , drop = FALSE]
    if (nrow(row) != 1L) {
      stop("Expected one H02 variation row for ", placement, " / ", id, ".")
    }
    format_ci(row$estimate, row$lower_95, row$upper_95)
  }
  shapley_value <- function(component_id) {
    row <- dominance[dominance$component == component_id, , drop = FALSE]
    if (nrow(row) != 1L) {
      stop(
        "Expected one H02 Shapley row for ",
        placement,
        " / ",
        component_id,
        "."
      )
    }
    format_ci(
      row$allocated_R2,
      row$allocated_R2_lower_95,
      row$allocated_R2_upper_95
    )
  }
  share_value <- function(component_id) {
    row <- dominance[dominance$component == component_id, , drop = FALSE]
    if (nrow(row) != 1L) {
      stop("Expected one H02 component share for ", component_id, ".")
    }
    format_percent_ci(
      row$share_of_full_model_R2,
      row$share_of_full_model_R2_lower_95,
      row$share_of_full_model_R2_upper_95
    )
  }
  comparison_value <- function(id, percent = FALSE) {
    row <- comparisons[comparisons$comparison_id == id, , drop = FALSE]
    if (nrow(row) != 1L) {
      stop("Expected one H02 comparison row for ", id, ".")
    }
    if (percent) {
      format_percent_ci(row$estimate, row$lower_95, row$upper_95)
    } else {
      format_ci(row$estimate, row$lower_95, row$upper_95, digits = 2L)
    }
  }

  rows <- rbind(
    c(
      "Shared local-clock curve",
      "Not applicable",
      shapley_value("common_time"),
      share_value("common_time")
    ),
    c(
      "Site pattern",
      variation_value("site_curve_variation"),
      shapley_value("site_pattern"),
      share_value("site_pattern")
    ),
    c(
      "Participant pattern",
      variation_value("participant_curve_variation"),
      shapley_value("participant_pattern"),
      share_value("participant_pattern")
    ),
    c(
      "Participant-day shift",
      variation_value("participant_day_intercept_variation"),
      shapley_value("participant_day"),
      share_value("participant_day")
    ),
    c(
      "Participant pattern + day shift",
      variation_value("participant_plus_day_variation"),
      "Not separately allocated",
      "Not applicable"
    ),
    c(
      "Participant / site",
      variation_value("participant_to_site_ratio"),
      comparison_value("participant_to_site_shapley_ratio"),
      "Not applicable"
    ),
    c(
      "(Participant + day) / site",
      variation_value("participant_plus_day_to_site_ratio"),
      comparison_value("participant_plus_day_to_site_shapley_ratio"),
      comparison_value(
        "participant_plus_day_share_of_heterogeneity",
        percent = TRUE
      )
    )
  )
  rows <- apply(rows, c(1, 2), html_escape)
  groups <- c(
    rep("Component summaries", 5L),
    rep("Participant-to-site comparisons", 2L)
  )
  full <- dominance[1L, , drop = FALSE]
  note <- paste0(
    "Full-model in-sample R² was ",
    format_ci(
      full$full_model_R2,
      full$full_model_R2_lower_95,
      full$full_model_R2_upper_95
    ),
    ". Fitted-curve variation is in squared log10(melEDI + 0.1 lx) prediction units; curve and Shapley ratios are unitless. Conditional Shapley values allocate in-sample R² with the shared local-clock curve as the mandatory baseline. Intervals are 95% percentile hierarchical cluster-bootstrap intervals from 2,000 replicates. Dispersion and Shapley credit are different estimands and must not be added or interpreted causally."
  )
  output <- file.path(
    asset_dir,
    paste0("tbl-plan-h02-", placement, "-variation-shapley.html")
  )
  write_planning_table_fragment(
    output,
    paste0("tbl-plan-h02-", placement, "-variation-shapley"),
    paste0(
      label,
      " fitted-curve dispersion and conditional Shapley allocation of in-sample model fit."
    ),
    c(
      "Quantity",
      "Fitted-curve result (95% CI)",
      "Conditional Shapley result (95% CI)",
      "Share (95% CI)"
    ),
    rows,
    groups,
    note
  )
}

h02_custom_paths <- c(
  build_h02_merged_table(
    "glasses",
    "primary_near_eye",
    "main__glasses__all_available",
    "Near-eye"
  ),
  build_h02_merged_table(
    "chest",
    "complementary_chest",
    "main__chest__all_available",
    "Chest"
  )
)

h01_primary <- read.csv(
  "artifacts/09_tables/H01/stage3/H01_stage3_primary_publication_summary.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
h01_descriptive <- read.csv(
  "artifacts/09_tables/descriptives/metric_descriptive_summary_replica.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
h01_r2 <- read.csv(
  "artifacts/09_tables/H01/stage3/H01_stage3_r2_table.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
h01_descriptive <- h01_descriptive[
  h01_descriptive$placement == "near_eye" &
    h01_descriptive$site == "Overall",
  ,
  drop = FALSE
]
h01_r2 <- h01_r2[
  h01_r2$run_id == "main__glasses__all_available" &
    h01_r2$row_type == "Metric",
  ,
  drop = FALSE
]
if (nrow(h01_primary) != 17L || nrow(h01_descriptive) != 17L) {
  stop("The H01/descriptive synthesis does not contain 17 metric rows.")
}

descriptive_document <- read_html(
  "_build/nathealth/notebooks/descriptives.html"
)
descriptive_table <- xml_find_first(
  descriptive_document,
  "//*[@id='tbl-near-eye-metrics']//table"
)
density_rows <- xml_find_all(descriptive_table, ".//tbody/tr[.//img]")
density_names <- vapply(
  density_rows,
  function(row) {
    first_cell <- xml_find_first(row, "./th | ./td")
    first_child <- xml_children(first_cell)[[1L]]
    normalize_caption(xml_text(first_child))
  },
  character(1)
)
density_sources <- vapply(
  density_rows,
  function(row) {
    xml_attr(xml_find_first(row, ".//img"), "src")
  },
  character(1)
)
if (
  length(density_names) != 17L ||
    anyDuplicated(density_names) ||
    any(!startsWith(density_sources, "data:image/png;base64,"))
) {
  stop("The accepted descriptive density thumbnails are incomplete.")
}
density_map <- setNames(density_sources, density_names)

format_adjusted_status <- function(p_value) {
  if (is.na(p_value)) {
    return("Not available")
  }
  p_display <- if (p_value < 0.001) "&lt;0.001" else sprintf("%.3f", p_value)
  decision <- if (p_value < 0.05) "FDR-supported" else "Not retained"
  paste0(decision, " (adjusted p ", p_display, ")")
}

format_r2_value <- function(metric_id, measure) {
  row <- h01_r2[
    h01_r2$metric_id == metric_id & h01_r2$measure == measure,
    ,
    drop = FALSE
  ]
  if (nrow(row) != 1L || is.na(row$estimate)) {
    return("Not available")
  }
  format_percent_ci(row$estimate, row$conf_low, row$conf_high)
}

format_adjusted_status_text <- function(p_value) {
  if (is.na(p_value)) {
    return("Not available")
  }
  p_display <- if (p_value < 0.001) "<0.001" else sprintf("%.3f", p_value)
  decision <- if (p_value < 0.05) "FDR-supported" else "Not retained"
  paste0(decision, "; adjusted p ", p_display)
}

format_three_decimals <- function(value) {
  formatC(
    value,
    format = "f",
    digits = 3L,
    big.mark = ",",
    decimal.mark = "."
  )
}

format_overall_values <- function(row) {
  if (identical(row$display_unit[[1]], "clock time")) {
    parts <- regexec(
      "^(.+) \\[([^,]+), ([^]]+)\\]$",
      row$median_middle_50_display[[1]],
      perl = TRUE
    )
    match <- regmatches(row$median_middle_50_display[[1]], parts)[[1]]
    if (length(match) != 4L) {
      stop("Could not parse an accepted clock-time summary.")
    }
    return(list(median = match[[2]], iqr = paste(match[[3]], "to", match[[4]])))
  }
  list(
    median = format_three_decimals(row$median[[1]]),
    iqr = paste(
      format_three_decimals(row$q1[[1]]),
      "to",
      format_three_decimals(row$q3[[1]])
    )
  )
}

h01_rows <- vector("list", 17L)
stream_labels <- c(
  "duration-based" = "Duration",
  "dynamics-based" = "Dynamics",
  "exposure-history-based" = "Exposure history",
  "level-based" = "Level",
  "spectrum-based" = "Spectrum",
  "timing-based" = "Timing"
)
for (index in seq_len(nrow(h01_primary))) {
  model_row <- h01_primary[index, , drop = FALSE]
  descriptive_id <- model_row$metric_id[[1]]
  descriptive_row <- h01_descriptive[
    h01_descriptive$metric_id == descriptive_id,
    ,
    drop = FALSE
  ]
  if (nrow(descriptive_row) != 1L) {
    stop("No unique descriptive row for ", descriptive_id, ".")
  }
  density <- density_map[[descriptive_row$manuscript_name[[1]]]]
  if (is.null(density)) {
    stop("No accepted density thumbnail for ", descriptive_id, ".")
  }

  overall <- format_overall_values(descriptive_row)
  metric <- descriptive_row$manuscript_name[[1]]
  definition <- descriptive_row$meaning_and_relevance[[1]]
  display_unit <- descriptive_row$display_unit[[1]]
  if (identical(descriptive_id, "dose_time_sensitive_corrected_medi")) {
    display_unit <- "klx·h"
    overall <- list(
      median = format_three_decimals(descriptive_row$median[[1]] / 1000),
      iqr = paste(
        format_three_decimals(descriptive_row$q1[[1]] / 1000),
        "to",
        format_three_decimals(descriptive_row$q3[[1]] / 1000)
      )
    )
  }
  if (identical(descriptive_id, "m10_mean_medi")) {
    metric <- "Brightest 10 h geometric mean"
    definition <- paste(
      "Offset geometric mean melEDI in the brightest supported 10-hour",
      "window; describes the strength of the main sustained daily exposure."
    )
  }
  if (identical(descriptive_id, "l10_mean_medi")) {
    metric <- "Darkest 10 h geometric mean"
    definition <- paste(
      "Offset geometric mean melEDI in the darkest supported 10-hour",
      "window; describes the sustained low-light period."
    )
  }
  density_cell <- paste0(
    '<img class="metric-density-thumb" style="width:190px;height:120px;',
    'object-fit:contain" src="',
    density,
    '" alt="Accepted site distribution thumbnail for ',
    html_escape(descriptive_row$manuscript_name[[1]]),
    '.">'
  )

  site_part <- h01_r2[
    h01_r2$metric_id == model_row$metric_id[[1]] &
      h01_r2$measure == "site_part_r2",
    ,
    drop = FALSE
  ]
  photoperiod_part <- h01_r2[
    h01_r2$metric_id == model_row$metric_id[[1]] &
      h01_r2$measure == "photoperiod_part_r2",
    ,
    drop = FALSE
  ]
  if (nrow(site_part) != 1L || nrow(photoperiod_part) != 1L) {
    stop(
      "Missing accepted H01 part-R² rows for ",
      model_row$metric_id[[1]],
      "."
    )
  }
  site_fdr <- format_adjusted_status_text(model_row$site_p_adjusted[[1]])
  site_r2 <- format_percent_ci(
    site_part$estimate,
    site_part$conf_low,
    site_part$conf_high
  )
  effect_label <- switch(
    model_row$photoperiod_effect_type[[1]],
    ratio = "Ratio",
    difference = "Difference",
    odds_ratio = "Odds ratio",
    model_row$photoperiod_effect_type[[1]]
  )
  photoperiod_effect <- paste0(
    effect_label,
    " per 1 h: ",
    format_ci(
      model_row$photoperiod_estimate_practical[[1]],
      model_row$photoperiod_conf_low_practical[[1]],
      model_row$photoperiod_conf_high_practical[[1]]
    )
  )
  photoperiod_fdr <- format_adjusted_status_text(
    model_row$photoperiod_p_adjusted[[1]]
  )
  photoperiod_r2 <- format_percent_ci(
    photoperiod_part$estimate,
    photoperiod_part$conf_low,
    photoperiod_part$conf_high
  )
  marginal_r2 <- format_r2_value(model_row$metric_id[[1]], "marginal_r2")
  conditional_r2 <- format_r2_value(
    model_row$metric_id[[1]],
    "conditional_r2"
  )
  participant_r2 <- format_r2_value(
    model_row$metric_id[[1]],
    "participant_associated_share"
  )
  h01_rows[[index]] <- data.frame(
    metric_family = stream_labels[[model_row$manuscript_category[[1]]]],
    metric = metric,
    definition = definition,
    unit = display_unit,
    median = overall$median,
    iqr = overall$iqr,
    participants = descriptive_row$n_participants[[1]],
    participant_days = descriptive_row$n_participant_days[[1]],
    distribution = density_cell,
    site_fdr_result = site_fdr,
    site_part_r2 = site_r2,
    photoperiod_estimate = photoperiod_effect,
    photoperiod_fdr_result = photoperiod_fdr,
    photoperiod_part_r2 = photoperiod_r2,
    marginal_r2 = marginal_r2,
    conditional_r2 = conditional_r2,
    participant_associated_r2 = participant_r2,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}
h01_rows <- do.call(rbind, h01_rows)
h01_group_order <- c(
  "Dynamics",
  "Level",
  "Duration",
  "Timing",
  "Exposure history",
  "Spectrum"
)
if (!setequal(unique(h01_rows$metric_family), h01_group_order)) {
  stop("The H01 metric-family row groups changed.")
}
h01_rows <- h01_rows[
  order(match(h01_rows$metric_family, h01_group_order)),
  ,
  drop = FALSE
]
h01_custom_path <- file.path(asset_dir, "tbl-plan-h01-metric-synthesis.html")
h01_gt <- gt::gt(
  h01_rows,
  rowname_col = "metric",
  id = "plan_h01_metric_synthesis_native"
) |>
  gt::cols_hide(columns = metric_family)
for (group_index in rev(seq_along(h01_group_order))) {
  group_label <- h01_group_order[[group_index]]
  h01_gt <- gt::tab_row_group(
    h01_gt,
    label = group_label,
    rows = metric_family == group_label,
    id = paste0("metric_group_", group_index)
  )
}
h01_gt <- h01_gt |>
  gt::tab_header(
    title = gt::md(
      "**Near-eye personal light-exposure metrics and their geographic and photoperiod context**"
    )
  ) |>
  gt::tab_spanner(
    label = "Descriptive summary",
    columns = c(
      unit,
      median,
      iqr,
      participants,
      participant_days,
      distribution
    )
  ) |>
  gt::tab_spanner(
    label = "Overall site",
    columns = c(site_fdr_result, site_part_r2)
  ) |>
  gt::tab_spanner(
    label = "Civil photoperiod",
    columns = c(
      photoperiod_estimate,
      photoperiod_fdr_result,
      photoperiod_part_r2
    )
  ) |>
  gt::tab_spanner(
    label = "Modelled variation",
    columns = c(
      marginal_r2,
      conditional_r2,
      participant_associated_r2
    )
  ) |>
  gt::cols_label(
    metric = "Metric",
    definition = "Definition/relevance",
    unit = "Unit",
    median = "Median",
    iqr = "IQR",
    participants = "N",
    participant_days = "Days",
    distribution = "Site distribution",
    site_fdr_result = "FDR result",
    site_part_r2 = "Part-R²",
    photoperiod_estimate = "Estimate per hour",
    photoperiod_fdr_result = "FDR result",
    photoperiod_part_r2 = "Part-R²",
    marginal_r2 = "Marginal R²",
    conditional_r2 = "Conditional R²",
    participant_associated_r2 = "Participant-associated R²"
  ) |>
  gt::fmt(
    columns = distribution,
    fn = function(values) lapply(values, gt::html)
  ) |>
  gt::cols_align(
    align = "left",
    columns = c(definition, site_fdr_result, photoperiod_fdr_result)
  ) |>
  gt::cols_align(
    align = "center",
    columns = -c(definition, site_fdr_result, photoperiod_fdr_result)
  ) |>
  gt::fmt_integer(
    columns = c(participants, participant_days),
    use_seps = TRUE
  ) |>
  gt::cols_width(
    metric ~ gt::px(190),
    definition ~ gt::px(230),
    unit ~ gt::px(70),
    median ~ gt::px(85),
    iqr ~ gt::px(125),
    participants ~ gt::px(55),
    participant_days ~ gt::px(60),
    distribution ~ gt::px(170),
    site_fdr_result ~ gt::px(120),
    site_part_r2 ~ gt::px(110),
    photoperiod_estimate ~ gt::px(150),
    photoperiod_fdr_result ~ gt::px(120),
    photoperiod_part_r2 ~ gt::px(110),
    marginal_r2 ~ gt::px(110),
    conditional_r2 ~ gt::px(110),
    participant_associated_r2 ~ gt::px(130)
  ) |>
  gt::tab_style(
    style = gt::cell_text(weight = "bold"),
    locations = gt::cells_row_groups()
  ) |>
  gt::opt_row_striping() |>
  gt::tab_options(
    table.font.size = gt::px(11),
    data_row.padding = gt::px(3),
    heading.align = "left"
  ) |>
  gt::tab_source_note(
    source_note = gt::md(paste0(
      "Overall distributions are median (interquartile range). N is the ",
      "participant count and Days is the participant-day count. Site and ",
      "photoperiod part-R² values can contain overlapping fitted information ",
      "and must not be summed. Participant-associated R² is the ",
      "conditional-minus-marginal contribution associated with the participant ",
      "random intercept and is undefined for participant-level outcomes. The ",
      "MDER uses the accepted mean of viable minute-level ratios in both the ",
      "descriptive and H01 model cells."
    ))
  )
write_gt_table_fragment(
  h01_custom_path,
  h01_gt,
  "tbl-plan-h01-metric-synthesis"
)

brown_main_rows <- data.frame(
  window = c("Daytime", "Pre-sleep", "Sleep"),
  recommendation = c(
    "At least 250 lx melanopic EDI during wake, excluding the three hours before sleep",
    "No more than 10 lx melanopic EDI during the three hours before reported sleep",
    "No more than 1 lx melanopic EDI during reported sleep; bedside sleep environment"
  ),
  pooled_minutes = c(
    "137,792/573,712 (24.0%)",
    "81,894/129,390 (63.3%)",
    "336,052/383,366 (87.7%)"
  ),
  work_day = c(
    "26.5 (24.4 to 28.6)",
    "61.9 (58.5 to 65.4)",
    "90.3 (88.7 to 91.8)"
  ),
  free_day = c(
    "21.6 (19.3 to 23.9)",
    "69.9 (66.3 to 73.5)",
    "84.1 (81.6 to 86.7)"
  ),
  difference = c(
    "-4.9 (-7.6 to -2.2)",
    "+8.0 (+3.3 to +12.7)",
    "-6.1 (-8.8 to -3.5)"
  ),
  adjusted_p = rep("<0.001", 3L),
  stringsAsFactors = FALSE
)
brown_main_custom_path <- file.path(
  asset_dir,
  "tbl-plan-brown-main-adherence.html"
)
brown_main_gt <- gt::gt(
  brown_main_rows,
  rowname_col = "window",
  id = "plan_brown_main_adherence_native"
) |>
  gt::tab_header(
    title = gt::md(
      "**Recommendation adherence by recommendation window and day type**"
    )
  ) |>
  gt::tab_spanner(
    label = "Observed minute-level adherence",
    columns = pooled_minutes
  ) |>
  gt::tab_spanner(
    label = "Site-average state-period model",
    columns = c(work_day, free_day, difference, adjusted_p)
  ) |>
  gt::cols_label(
    window = "Window",
    recommendation = "Recommendation",
    pooled_minutes = "Minutes meeting recommendation, n/N (%)",
    work_day = "Work day, % (95% CI)",
    free_day = "Free day, % (95% CI)",
    difference = "Free minus Work, percentage points (95% CI)",
    adjusted_p = "FDR-adjusted p"
  ) |>
  gt::cols_align(align = "left", columns = recommendation) |>
  gt::cols_align(
    align = "center",
    columns = c(pooled_minutes, work_day, free_day, difference, adjusted_p)
  ) |>
  gt::cols_width(
    window ~ gt::px(85),
    recommendation ~ gt::px(270),
    pooled_minutes ~ gt::px(150),
    work_day ~ gt::px(130),
    free_day ~ gt::px(130),
    difference ~ gt::px(155),
    adjusted_p ~ gt::px(85)
  ) |>
  gt::opt_row_striping() |>
  gt::tab_options(
    table.font.size = gt::px(12),
    data_row.padding = gt::px(5),
    heading.align = "left"
  ) |>
  gt::tab_source_note(
    source_note = gt::md(paste0(
      "Observed pooled-minute fractions and site-average model estimates are ",
      "distinct estimands. Each of the nine sites contributes equally to the ",
      "model estimates."
    ))
  )
write_gt_table_fragment(
  brown_main_custom_path,
  brown_main_gt,
  "tbl-plan-brown-main-adherence"
)

sample_contract <- read.csv(
  "audit/descriptives/sample_count_contract.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
sample_contract_key <- paste(sample_contract$stage, sample_contract$placement)
required_sample_keys <- c(
  "Available normalized participant metadata participant roster",
  "At least 80% complete before all-zero screen near_eye",
  "Exact all-zero days excluded near_eye",
  "Main dataset after all-zero screen near_eye",
  "At least 80% complete before all-zero screen chest",
  "Exact all-zero days excluded chest",
  "Main dataset after all-zero screen chest",
  "Paired main subset paired"
)
if (
  nrow(sample_contract) != length(required_sample_keys) ||
    !setequal(sample_contract_key, required_sample_keys) ||
    anyDuplicated(sample_contract_key)
) {
  stop("The accepted descriptive sample-flow contract changed structure.")
}

sample_value <- function(stage, placement, column) {
  row <- sample_contract[
    sample_contract$stage == stage & sample_contract$placement == placement,
    ,
    drop = FALSE
  ]
  if (nrow(row) != 1L || is.na(row[[column]][[1]])) {
    stop(
      "No unique accepted sample-flow value for ",
      placement,
      " / ",
      stage,
      " / ",
      column,
      "."
    )
  }
  as.numeric(row[[column]][[1]])
}

sample_flow_rows <- data.frame(
  domain = c(
    "Participant roster",
    rep("Primary near-eye sensor position", 5L),
    rep("Complementary chest sensor position", 5L),
    rep("Paired main subset", 2L)
  ),
  stage = c(
    "Available normalized participant metadata",
    "At least 80% complete before all-zero screen",
    "Exact all-zero days excluded",
    rep("Final descriptive dataset", 3L),
    "At least 80% complete before all-zero screen",
    "Exact all-zero days excluded",
    rep("Final descriptive dataset", 3L),
    rep("Paired main subset", 2L)
  ),
  quantity = c(
    "Participants",
    "Participant-days",
    "Participant-days",
    "Participants",
    "Participant-days",
    "One-minute real observations",
    "Participant-days",
    "Participant-days",
    "Participants",
    "Participant-days",
    "One-minute real observations",
    "Participants",
    "Paired participant-days"
  ),
  count = c(
    sample_value(
      "Available normalized participant metadata",
      "participant roster",
      "participants"
    ),
    sample_value(
      "At least 80% complete before all-zero screen",
      "near_eye",
      "participant_days"
    ),
    sample_value(
      "Exact all-zero days excluded",
      "near_eye",
      "participant_days"
    ),
    sample_value(
      "Main dataset after all-zero screen",
      "near_eye",
      "participants"
    ),
    sample_value(
      "Main dataset after all-zero screen",
      "near_eye",
      "participant_days"
    ),
    sample_value(
      "Main dataset after all-zero screen",
      "near_eye",
      "one_minute_real_observations"
    ),
    sample_value(
      "At least 80% complete before all-zero screen",
      "chest",
      "participant_days"
    ),
    sample_value(
      "Exact all-zero days excluded",
      "chest",
      "participant_days"
    ),
    sample_value(
      "Main dataset after all-zero screen",
      "chest",
      "participants"
    ),
    sample_value(
      "Main dataset after all-zero screen",
      "chest",
      "participant_days"
    ),
    sample_value(
      "Main dataset after all-zero screen",
      "chest",
      "one_minute_real_observations"
    ),
    sample_value("Paired main subset", "paired", "participants"),
    sample_value("Paired main subset", "paired", "participant_days")
  ),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
sample_flow_custom_path <- file.path(
  asset_dir,
  "tbl-plan-descriptive-sample-flow.html"
)
sample_flow_gt <- gt::gt(
  sample_flow_rows,
  id = "plan_descriptive_sample_flow_native"
) |>
  gt::cols_hide(columns = domain)
sample_flow_groups <- unique(sample_flow_rows$domain)
for (group_index in rev(seq_along(sample_flow_groups))) {
  group_label <- sample_flow_groups[[group_index]]
  sample_flow_gt <- gt::tab_row_group(
    sample_flow_gt,
    label = group_label,
    rows = domain == group_label,
    id = paste0("sample_domain_", group_index)
  )
}
sample_flow_gt <- sample_flow_gt |>
  gt::tab_header(
    title = gt::md("**Descriptive sample flow and analytical support**")
  ) |>
  gt::cols_label(stage = "Stage", quantity = "Quantity", count = "Count") |>
  gt::fmt_integer(columns = count, use_seps = TRUE) |>
  gt::cols_align(align = "left", columns = c(stage, quantity)) |>
  gt::cols_align(align = "right", columns = count) |>
  gt::cols_width(
    stage ~ gt::px(330),
    quantity ~ gt::px(220),
    count ~ gt::px(135)
  ) |>
  gt::tab_style(
    style = gt::cell_text(weight = "bold"),
    locations = gt::cells_row_groups()
  ) |>
  gt::opt_row_striping() |>
  gt::tab_options(
    table.font.size = gt::px(13),
    data_row.padding = gt::px(6),
    heading.align = "left"
  ) |>
  gt::tab_source_note(
    source_note = gt::md(
      "Counts use their stated denominator. An excluded participant-day is an all-zero day, not necessarily an excluded participant. The paired row reports paired participant-days, not minute-level observation pairs."
    )
  )
write_gt_table_fragment(
  sample_flow_custom_path,
  sample_flow_gt,
  "tbl-plan-descriptive-sample-flow"
)

brown_cross_window <- read.csv(
  brown_cross_window_source_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
required_cross_window_columns <- c(
  "association_level",
  "target_state",
  "wake_contrast_percentage_points",
  "response_effect_percentage_points",
  "response_conf_low_percentage_points",
  "response_conf_high_percentage_points",
  "adjusted_p_value",
  "reference_weighting",
  "association_order"
)
if (
  nrow(brown_cross_window) != 4L ||
    !all(required_cross_window_columns %in% names(brown_cross_window)) ||
    anyDuplicated(brown_cross_window$association_order) ||
    !identical(sort(brown_cross_window$association_order), 1:4) ||
    !identical(
      unique(brown_cross_window$wake_contrast_percentage_points),
      10L
    ) ||
    !identical(
      unique(brown_cross_window$reference_weighting),
      "equal 9 sites; 50:50 Work/Free"
    )
) {
  stop("The accepted Brown cross-window source changed structure.")
}
brown_cross_window <- brown_cross_window[
  order(brown_cross_window$association_order),
  ,
  drop = FALSE
]
format_adjusted_p <- function(value) {
  if (is.na(value)) {
    return("Not available")
  }
  if (value < 0.001) "<0.001" else sprintf("%.3f", value)
}
brown_cross_window_rows <- data.frame(
  association_level = ifelse(
    brown_cross_window$association_level == "within",
    "Within participant, linked cycle",
    "Between participants, observed monitoring-period average"
  ),
  outcome_window = brown_cross_window$target_state,
  difference = vapply(
    seq_len(nrow(brown_cross_window)),
    function(index) {
      format_ci(
        brown_cross_window$response_effect_percentage_points[[index]],
        brown_cross_window$response_conf_low_percentage_points[[index]],
        brown_cross_window$response_conf_high_percentage_points[[index]],
        digits = 2L
      )
    },
    character(1)
  ),
  fdr_adjusted_p = vapply(
    brown_cross_window$adjusted_p_value,
    format_adjusted_p,
    character(1)
  ),
  fdr_correction_set = rep(
    "Four prespecified primary cross-window tests",
    nrow(brown_cross_window)
  ),
  interpretation = ifelse(
    brown_cross_window$association_level == "within",
    ifelse(
      brown_cross_window$target_state == "Sleep",
      paste(
        "No retained evidence that a cycle with 10 percentage points higher",
        "Daytime adherence had different Sleep adherence; the day-level claim",
        "is withheld because serial dependence remains unresolved."
      ),
      paste(
        "No retained evidence that a cycle with 10 percentage points higher",
        "Daytime adherence had different Pre-sleep adherence; the day-level",
        "claim is withheld because serial dependence remains unresolved."
      )
    ),
    ifelse(
      brown_cross_window$target_state == "Sleep",
      paste(
        "Participants with 10 percentage points higher average Daytime",
        "adherence had 2.52 percentage points lower average Sleep adherence",
        "over the monitoring period."
      ),
      paste(
        "Participants with 10 percentage points higher average Daytime",
        "adherence had 3.59 percentage points lower average Pre-sleep",
        "adherence over the monitoring period."
      )
    )
  ),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
brown_cross_window_custom_path <- file.path(
  asset_dir,
  "tbl-plan-brown-cross-window-associations.html"
)
brown_cross_window_gt <- gt::gt(
  brown_cross_window_rows,
  id = "plan_brown_cross_window_associations_native"
) |>
  gt::cols_hide(columns = association_level)
brown_cross_window_groups <- unique(brown_cross_window_rows$association_level)
for (group_index in rev(seq_along(brown_cross_window_groups))) {
  group_label <- brown_cross_window_groups[[group_index]]
  brown_cross_window_gt <- gt::tab_row_group(
    brown_cross_window_gt,
    label = group_label,
    rows = association_level == group_label,
    id = paste0("association_level_", group_index)
  )
}
brown_cross_window_gt <- brown_cross_window_gt |>
  gt::tab_header(
    title = gt::md(
      "**Exploratory cross-window recommendation-adherence associations**"
    )
  ) |>
  gt::cols_label(
    outcome_window = "Outcome window",
    difference = "Difference per +10 percentage points Daytime adherence, percentage points (95% CI)",
    fdr_adjusted_p = "FDR-adjusted p",
    fdr_correction_set = "FDR-correction set/family",
    interpretation = "Interpretation for recommendation adherence"
  ) |>
  gt::cols_align(
    align = "left",
    columns = c(
      outcome_window,
      fdr_correction_set,
      interpretation
    )
  ) |>
  gt::cols_align(
    align = "center",
    columns = c(difference, fdr_adjusted_p)
  ) |>
  gt::cols_width(
    outcome_window ~ gt::px(105),
    difference ~ gt::px(260),
    fdr_adjusted_p ~ gt::px(105),
    fdr_correction_set ~ gt::px(205),
    interpretation ~ gt::px(330)
  ) |>
  gt::tab_style(
    style = gt::cell_text(weight = "bold"),
    locations = gt::cells_row_groups()
  ) |>
  gt::opt_row_striping() |>
  gt::tab_options(
    table.font.size = gt::px(12),
    data_row.padding = gt::px(6),
    heading.align = "left"
  ) |>
  gt::tab_source_note(
    source_note = gt::md(paste0(
      "All four tests form one FDR-correction set. Site-standardized estimates ",
      "give nine sites equal weight and use 50:50 Work/Free weighting. The ",
      "primary sample contained 1,376 target-window rows from 140 participants ",
      "and 761 linked cycles. Within-participant claims are withheld because ",
      "temporal dependence remains unresolved. Between-participant estimates ",
      "describe observed monitoring-period averages, not rankings, stable ",
      "traits, or causal effects. Confidence intervals are not multiplicity ",
      "adjusted."
    ))
  )
write_gt_table_fragment(
  brown_cross_window_custom_path,
  brown_cross_window_gt,
  "tbl-plan-brown-cross-window-associations"
)

additional_table_specs <- data.frame(
  reader_html = rep("_build/nathealth/notebooks/descriptives.html", 3L),
  table_id = c(
    "tbl-participant-site",
    "tbl-near-eye-metrics",
    "tbl-recommendation-context"
  ),
  stringsAsFactors = FALSE
)
additional_table_records <- vector("list", nrow(additional_table_specs))
for (index in seq_len(nrow(additional_table_specs))) {
  html_path <- additional_table_specs$reader_html[[index]]
  table_id <- additional_table_specs$table_id[[index]]
  document <- read_html(html_path)
  endpoint <- xml_find_all(document, paste0("//*[@id='", table_id, "']"))
  if (length(endpoint) != 1L) {
    stop("Expected one additional descriptive table endpoint: ", table_id)
  }
  display <- xml_find_all(
    endpoint,
    ".//*[contains(concat(' ', normalize-space(@class), ' '), ' cell-output-display ')]"
  )
  if (
    length(display) != 1L || length(xml_find_all(display, ".//table")) != 1L
  ) {
    stop("Expected one additional native table body: ", table_id)
  }
  caption_node <- xml_find_first(endpoint, ".//figcaption")
  if (inherits(caption_node, "xml_missing")) {
    stop("Missing additional descriptive caption: ", table_id)
  }
  fragment_path <- file.path(asset_dir, paste0(table_id, ".html"))
  writeLines(
    build_semantic_table_fragment(display, table_id, html_path),
    fragment_path,
    useBytes = TRUE
  )
  additional_table_records[[index]] <- data.frame(
    table_id = table_id,
    accepted_caption = normalize_caption(xml_text(caption_node)),
    table_fragment = fragment_path,
    table_fragment_sha256 = sha256_file(fragment_path),
    table_fragment_bytes = file_bytes(fragment_path),
    stringsAsFactors = FALSE
  )
}
additional_table_inventory <- do.call(rbind, additional_table_records)
additional_table_inventory_path <- file.path(
  asset_dir,
  "additional_descriptive_table_inventory.csv"
)
write.csv(
  additional_table_inventory,
  additional_table_inventory_path,
  row.names = FALSE,
  na = ""
)

inventory_path <- file.path(asset_dir, "accepted_output_inventory.csv")
write.csv(inventory, inventory_path, row.names = FALSE, na = "")

semantic_summary <- do.call(rbind, semantic_summaries)
semantic_summary_path <- file.path(
  asset_dir,
  "table_preview_semantic_summary.csv"
)
write.csv(semantic_summary, semantic_summary_path, row.names = FALSE, na = "")

semantic_ledger <- do.call(rbind, semantic_ledgers)
semantic_ledger_path <- file.path(
  asset_dir,
  "table_preview_semantic_ledger.csv"
)
write.csv(semantic_ledger, semantic_ledger_path, row.names = FALSE, na = "")

additional_figure_inventory <- data.frame(
  path = c(
    "artifacts/10_figures/descriptives/chest_site_profiles.png",
    "artifacts/10_figures/descriptives/near_eye_metric_distributions.png",
    "artifacts/10_figures/descriptives/time_series_to_metrics.png",
    "artifacts/10_figures/descriptives/latitude_photoperiod_diagnostic.png",
    brown_copy_specs$destination,
    "artifacts/10_figures/H03/H03_reader_temporal_near_eye.png",
    "artifacts/10_figures/H04/H04_temporal_near_eye.png",
    "artifacts/10_figures/H06/H06_reader_temporal_day_type.png",
    "artifacts/10_figures/H06/H06_reader_temporal_activity.png",
    "artifacts/10_figures/H09/H09_observed_timing_patterns.png"
  ),
  expected_sha256 = c(
    "b9727d9ff587548f77aa18a5483ab6430c242c721a291b09cfd059541b58f765",
    "060d1dcb3ec519ed1d74904c5457cc945346c53e25d08a9ea0f083d29f184d04",
    "c6f080bd520c85f219749b2911702f6d29c3165bb2097b03e8b8437c2da96a1d",
    "b027935213185841c3b565dfbb440cf2fcf07dca03b4e19d2c1744270fd66ed6",
    brown_copy_specs$sha256,
    "8455a5824c3b232040a92ee604cc7ce30360c814bf1f5e2293fc5b8ef74c7a00",
    "8f048e0716e036413f541054a03c521941b4728f661871223b3e4c238991b3d4",
    "7f8de8989621ccd7b51cd7940bc513dc3883d09c098052335efea172bab28c30",
    "718c0917cb0aa58e2308cf8cdf9f2af144f80d55769044cc1cc294a84095c3d0",
    "a23cb2a9a90a232ae9bf3f94ec7b1c5ac0e3c83933d056c0920ffd59e8e0eb59"
  ),
  role = c(
    rep("accepted_descriptive_supplementary_figure", 4L),
    "accepted_brown_stage3_figure",
    "owner_sealed_brown_s5_raster_composite",
    "owner_sealed_brown_s5_vector_composite",
    "accepted_h03_temporal_main_figure_component",
    "accepted_h04_temporal_main_figure_component",
    "accepted_h06_temporal_supplementary_figure",
    "accepted_h06_temporal_supplementary_figure",
    "owner_verified_h09_source_ready_candidate"
  ),
  stringsAsFactors = FALSE
)
additional_figure_inventory$sha256 <- vapply(
  additional_figure_inventory$path,
  sha256_file,
  character(1)
)
additional_figure_inventory$bytes <- vapply(
  additional_figure_inventory$path,
  file_bytes,
  numeric(1)
)
if (
  !all(
    additional_figure_inventory$sha256 ==
      additional_figure_inventory$expected_sha256
  )
) {
  stop("An additional planning figure changed from its accepted identity.")
}
additional_figure_inventory_path <- file.path(
  asset_dir,
  "additional_figure_inventory.csv"
)
write.csv(
  additional_figure_inventory,
  additional_figure_inventory_path,
  row.names = FALSE,
  na = ""
)

provenance_paths <- c(
  "manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd",
  "index.qmd",
  "manuscript/R0_NatMed/ZaunerEtAl2026_NatMed.docx",
  "audit/decisions/brown_adherence_stage3_stage4_language_harmonization_source_independent_acceptance.md",
  "audit/decisions/brown_adherence_stage3_order50_independent_acceptance.md",
  "audit/decisions/brown_adherence_stage4_order51_environment_retry_independent_acceptance.md",
  "audit/manuscript_nature_health/narrative_blueprint.qmd",
  "audit/report_harmonization/phase2_main_supplement_output_catalog.csv",
  "audit/report_harmonization/main_output_shortlist.csv",
  phase4_path,
  "audit/report_harmonization/report018_final_corpus_independent_acceptance.md",
  "audit/report_harmonization/report018_final_corpus_independent_acceptance_manifest.csv",
  "audit/hypotheses/H09/H09_stage3_observed_figure_source_verification.md",
  "artifacts/12_manifests/H09/H09_stage3_observed_figure_source_seal.csv",
  names(pinned_table_inputs),
  semantic_engine_path,
  semantic_wrapper_path
)
provenance_paths <- unique(provenance_paths)
provenance <- data.frame(
  path = provenance_paths,
  sha256 = vapply(provenance_paths, sha256_file, character(1)),
  bytes = vapply(provenance_paths, file_bytes, numeric(1)),
  stringsAsFactors = FALSE
)
provenance_path <- file.path(asset_dir, "planning_source_inventory.csv")
write.csv(provenance, provenance_path, row.names = FALSE, na = "")

table_fragment_paths <- c(
  inventory$table_fragment,
  inventory$table_continuation_fragment[nzchar(
    inventory$table_continuation_fragment
  )],
  additional_table_inventory$table_fragment,
  h02_custom_paths,
  h01_custom_path,
  brown_main_custom_path,
  sample_flow_custom_path,
  brown_cross_window_custom_path
)
generated_paths <- c(
  brown_copy_specs$destination,
  table_fragment_paths,
  inventory_path,
  provenance_path,
  semantic_summary_path,
  semantic_ledger_path,
  additional_table_inventory_path,
  additional_figure_inventory_path,
  selection_figure_inputs$path
)
manifest <- data.frame(
  path = generated_paths,
  sha256 = vapply(generated_paths, sha256_file, character(1)),
  bytes = vapply(generated_paths, file_bytes, numeric(1)),
  role = c(
    rep("brown_planning_figure_copy", nrow(brown_copy_specs)),
    rep("table_preview_or_accepted_row_assembly", length(table_fragment_paths)),
    "accepted_output_inventory",
    "planning_source_inventory",
    "table_preview_semantic_summary",
    "table_preview_reversible_semantic_ledger",
    "additional_descriptive_table_inventory",
    "additional_figure_inventory",
    rep("accepted_selection_figure_input", nrow(selection_figure_inputs))
  ),
  stringsAsFactors = FALSE
)
manifest_path <- file.path(asset_dir, "selection_asset_manifest.csv")
write.csv(manifest, manifest_path, row.names = FALSE, na = "")

cat(
  "MANUSCRIPT_DISPLAY_SELECTION_ASSETS=PASS",
  paste0("outputs=", nrow(inventory)),
  paste0("tables=", length(table_fragment_paths)),
  paste0("figures=", length(inventory$figure_id)),
  paste0("manifest=", nrow(manifest)),
  paste0("semantic_substitutions=", sum(semantic_summary$total_substitutions)),
  paste0("R=", as.character(getRversion())),
  "\n"
)
