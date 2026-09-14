#!/usr/bin/env Rscript

# Non-scientific structural and provenance checks for REPORT-018 H02 order 39b.

suppressPackageStartupMessages({
  library(digest)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
stopifnot(identical(as.character(getRversion()), "4.6.1"))
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H02/report018_order39_companion_render"
)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

record <- data.frame(
  check = character(),
  status = character(),
  detail = character(),
  stringsAsFactors = FALSE
)
add_check <- function(check, condition, detail) {
  record <<- rbind(
    record,
    data.frame(
      check = check,
      status = if (isTRUE(condition)) "PASS" else "FAIL",
      detail = as.character(detail),
      stringsAsFactors = FALSE
    )
  )
  if (!isTRUE(condition)) {
    stop(sprintf("%s: %s", check, detail), call. = FALSE)
  }
  invisible(TRUE)
}

companion_rel <- paste0(
  "_build/nathealth/audit/hypotheses/H02/",
  "H02_analysis_preparation.html"
)
result_rel <- "_build/nathealth/notebooks/hypotheses/H02.html"
companion_path <- file.path(root, companion_rel)
result_path <- file.path(root, result_rel)
build_root <- normalizePath(
  file.path(root, "_build/nathealth"),
  winslash = "/",
  mustWork = TRUE
)

wrapper <- new.env(parent = globalenv())
sys.source(
  file.path(root, "scripts/report_harmonization/post_render_gt_html_semantics.R"),
  envir = wrapper
)
wrapper$assert_post_render_runtime()
engine <- wrapper$load_repair_engine(root)
semantic_state <- wrapper$inspect_gt_html_state(companion_path, engine)
add_check(
  "semantic_state",
  identical(semantic_state$disposition, "ALREADY_REPAIRED") &&
    identical(semantic_state$table_count, 16L) &&
    identical(semantic_state$id_count, 80L) &&
    identical(semantic_state$headers_count, 517L),
  sprintf(
    "%s; tables=%d; ids=%d; headers=%d",
    semantic_state$disposition,
    semantic_state$table_count,
    semantic_state$id_count,
    semantic_state$headers_count
  )
)

semantic_dir <- "/private/tmp/H02-order39b-semantics.JqsD9m"
summary_path <- file.path(
  semantic_dir,
  "gt_html_semantic_post_render_summary.csv"
)
summary <- utils::read.csv(summary_path, check.names = FALSE)
ledger_path <- file.path(semantic_dir, summary$ledger_file[[1L]])
ledger <- utils::read.csv(
  ledger_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
post_raw <- engine$read_file_raw(companion_path)
reverse_raw <- engine$apply_raw_replacements(post_raw, ledger, reverse = TRUE)
forward_raw <- engine$apply_raw_replacements(reverse_raw, ledger, reverse = FALSE)
add_check(
  "semantic_summary",
  nrow(summary) == 1L &&
    identical(summary$target[[1L]], companion_rel) &&
    identical(summary$disposition[[1L]], "REPAIRED") &&
    identical(as.integer(summary$table_count[[1L]]), 16L) &&
    identical(as.integer(summary$id_count[[1L]]), 80L) &&
    identical(as.integer(summary$headers_count[[1L]]), 517L) &&
    identical(as.integer(summary$total_substitutions[[1L]]), nrow(ledger)),
  sprintf("rows=%d; ledger=%d", nrow(summary), nrow(ledger))
)
add_check(
  "semantic_exact_reverse",
  identical(engine$sha256_raw(reverse_raw), summary$pre_sha256[[1L]]) &&
    identical(engine$sha256_raw(post_raw), summary$post_sha256[[1L]]) &&
    identical(forward_raw, post_raw),
  paste0(
    "pre=", engine$sha256_raw(reverse_raw),
    "; post=", engine$sha256_raw(post_raw)
  )
)

companion_doc <- read_html(companion_path)
result_doc <- read_html(result_path)
companion_main <- xml_find_first(
  companion_doc,
  "//main[@id='quarto-document-content']"
)
result_main <- xml_find_first(result_doc, "//main[@id='quarto-document-content']")
add_check(
  "main_regions",
  !inherits(companion_main, "xml_missing") &&
    !inherits(result_main, "xml_missing"),
  "companion and result main regions present"
)

expected_tables <- c(
  "tbl-h02-prep-boundary",
  "tbl-h02-prep-inputs",
  "tbl-h02-prep-support",
  "tbl-h02-prep-scenarios",
  "tbl-h02-prep-near-site-sample",
  "tbl-h02-prep-chest-site-sample",
  "tbl-h02-prep-parameters",
  "tbl-h02-prep-primary-fits",
  "tbl-h02-prep-structure-checks",
  "tbl-h02-prep-ar-boundaries",
  "tbl-h02-prep-diagnostic-map",
  "tbl-h02-prep-sensitivity-map",
  "tbl-h02-prep-module-map",
  "tbl-h02-prep-script-map",
  "tbl-h02-prep-manifests",
  "tbl-h02-prep-environment"
)
expected_figures <- c(
  "fig-h02-prep-response-distribution",
  "fig-h02-prep-clock-support",
  "fig-h02-prep-day-support",
  "fig-h02-prep-ar-change"
)
all_ids <- xml_attr(xml_find_all(companion_doc, ".//*[@id]"), "id")
all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]
add_check(
  "document_unique_ids",
  !anyDuplicated(all_ids),
  sprintf("document ids=%d", length(all_ids))
)

endpoint_order <- xml_attr(
  xml_find_all(companion_main, ".//*[@id]"),
  "id"
)
table_order <- endpoint_order[endpoint_order %in% expected_tables]
figure_order <- endpoint_order[endpoint_order %in% expected_figures]
add_check(
  "table_endpoint_order",
  identical(table_order, expected_tables),
  paste(table_order, collapse = "; ")
)
add_check(
  "figure_endpoint_order",
  identical(figure_order, expected_figures),
  paste(figure_order, collapse = "; ")
)

endpoint_caption_count <- vapply(
  c(expected_tables, expected_figures),
  function(endpoint) {
    node <- xml_find_first(companion_main, paste0(".//*[@id='", endpoint, "']"))
    if (inherits(node, "xml_missing")) return(0L)
    length(xml_find_all(node, ".//figcaption"))
  },
  integer(1)
)
add_check(
  "captions_complete",
  all(endpoint_caption_count == 1L),
  sprintf("endpoints=%d", length(endpoint_caption_count))
)

figure_images <- lapply(expected_figures, function(endpoint) {
  node <- xml_find_first(companion_main, paste0(".//*[@id='", endpoint, "']"))
  xml_find_all(node, ".//img")
})
figure_image_count <- vapply(figure_images, length, integer(1))
figure_alt <- unlist(lapply(figure_images, xml_attr, attr = "alt"), use.names = FALSE)
add_check(
  "figure_images_and_alt",
  all(figure_image_count == 1L) &&
    length(figure_alt) == 4L &&
    all(!is.na(figure_alt)) &&
    all(nzchar(trimws(figure_alt))),
  paste(figure_image_count, collapse = ",")
)

mermaid <- xml_find_all(
  companion_main,
  ".//*[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
)
add_check(
  "mermaid_td",
  length(mermaid) == 1L &&
    grepl("flowchart TD", xml_text(mermaid[[1L]]), fixed = TRUE),
  sprintf("mermaid=%d", length(mermaid))
)

error_xpath <- paste0(
  ".//*[contains(concat(' ', normalize-space(@class), ' '),",
  " ' cell-output-error ') or ",
  "contains(concat(' ', normalize-space(@class), ' '), ' cell-output-warning ') or ",
  "contains(concat(' ', normalize-space(@class), ' '), ' cell-output-stderr ') or ",
  "contains(concat(' ', normalize-space(@class), ' '), ' quarto-unresolved-ref ')]"
)
error_nodes <- c(
  xml_find_all(companion_main, error_xpath),
  xml_find_all(result_main, error_xpath)
)
add_check(
  "no_embedded_errors",
  length(error_nodes) == 0L &&
    !grepl("Execution halted", xml_text(companion_main), fixed = TRUE),
  sprintf("nodes=%d", length(error_nodes))
)

path_within <- function(path, directory) {
  identical(path, directory) || startsWith(path, paste0(directory, "/"))
}

link_rows <- list()
audit_page_links <- function(document, page_path, page_name) {
  anchors <- xml_find_all(document, "//a[@href]")
  rows <- vector("list", length(anchors))
  page_ids <- xml_attr(xml_find_all(document, ".//*[@id]"), "id")
  page_ids <- page_ids[!is.na(page_ids) & nzchar(page_ids)]
  for (index in seq_along(anchors)) {
    anchor <- anchors[[index]]
    href <- xml_attr(anchor, "href")
    text_label <- trimws(gsub("[[:space:]]+", " ", xml_text(anchor)))
    image_alt <- xml_attr(xml_find_first(anchor, ".//img[@alt]"), "alt")
    labels <- c(
      text_label,
      xml_attr(anchor, "aria-label"),
      xml_attr(anchor, "title"),
      image_alt
    )
    labels <- labels[!is.na(labels) & nzchar(trimws(labels))]
    forbidden <- grepl("file://|_build|/Users/", href, perl = TRUE)
    dynamic <- grepl("^(?:javascript:|mailto:|tel:)", href, ignore.case = TRUE) ||
      identical(href, "#")
    external <- startsWith(href, "//") ||
      grepl("^https?://", href, ignore.case = TRUE)
    internal <- !dynamic && !external
    resolved <- TRUE
    target_path <- ""
    fragment <- ""
    if (internal) {
      fragment <- if (grepl("#", href, fixed = TRUE)) {
        URLdecode(sub("^[^#]*#", "", href))
      } else {
        ""
      }
      href_path <- URLdecode(sub("[?#].*$", "", href))
      if (!nzchar(href_path)) {
        target_path <- page_path
      } else if (startsWith(href_path, "/")) {
        target_path <- file.path(build_root, substring(href_path, 2L))
      } else {
        target_path <- file.path(dirname(page_path), href_path)
      }
      target_path <- normalizePath(target_path, winslash = "/", mustWork = FALSE)
      if (dir.exists(target_path)) target_path <- file.path(target_path, "index.html")
      resolved <- path_within(target_path, build_root) && file.exists(target_path)
      if (resolved && nzchar(fragment)) {
        target_ids <- if (identical(target_path, page_path)) {
          page_ids
        } else if (tolower(tools::file_ext(target_path)) %in% c("html", "htm")) {
          target_doc <- read_html(target_path)
          ids <- xml_attr(xml_find_all(target_doc, ".//*[@id]"), "id")
          ids[!is.na(ids) & nzchar(ids)]
        } else {
          character()
        }
        resolved <- fragment %in% target_ids
      }
    }
    rows[[index]] <- data.frame(
      page = page_name,
      href = href,
      accessible_label = paste(labels, collapse = " | "),
      kind = if (dynamic) "dynamic" else if (external) "external" else "internal",
      target_path = target_path,
      fragment = fragment,
      label_required = !grepl("^#cb[0-9]+-[0-9]+$", href),
      forbidden = forbidden,
      resolved = resolved,
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, rows)
}

link_audit <- rbind(
  audit_page_links(companion_doc, companion_path, "companion"),
  audit_page_links(result_doc, result_path, "result")
)
add_check(
  "link_labels",
  all(nzchar(link_audit$accessible_label[link_audit$label_required])),
  sprintf(
    "links=%d; generated-code-line-links=%d",
    nrow(link_audit),
    sum(!link_audit$label_required)
  )
)
add_check(
  "internal_links",
  all(link_audit$resolved[link_audit$kind == "internal"]) &&
    !any(link_audit$forbidden),
  sprintf(
    "internal=%d; unresolved=%d; forbidden=%d",
    sum(link_audit$kind == "internal"),
    sum(!link_audit$resolved),
    sum(link_audit$forbidden)
  )
)

companion_to_result <- link_audit$page == "companion" &
  grepl("notebooks/hypotheses/H02[.]html", link_audit$href)
result_to_companion <- link_audit$page == "result" &
  grepl("H02_analysis_preparation[.]html", link_audit$href)
add_check(
  "reciprocal_h02_links",
  any(companion_to_result & link_audit$resolved) &&
    any(result_to_companion & link_audit$resolved),
  sprintf(
    "companion-to-result=%d; result-to-companion=%d",
    sum(companion_to_result),
    sum(result_to_companion)
  )
)

active_nav <- xml_find_all(
  companion_doc,
  paste0(
    "//a[contains(concat(' ', normalize-space(@class), ' '), ' active ') ",
    "and contains(@href, 'H02_analysis_preparation.html')]"
  )
)
add_check(
  "active_navigation",
  length(active_nav) >= 1L,
  sprintf("active links=%d", length(active_nav))
)

supplementary_links <- link_audit[
  grepl("supplementary_information[.]html", link_audit$href),
  ,
  drop = FALSE
]
add_check(
  "supplementary_target",
  nrow(supplementary_links) >= 1L &&
    all(supplementary_links$resolved) &&
    identical(
      artifact_sha256(file.path(build_root, "supplementary_information.html")),
      "a0b5d097b12ee4a7cbfbcd5cb4740f1eac81bf1c9dba1e4e00a9d5644bfec4eb"
    ),
  sprintf("links=%d", nrow(supplementary_links))
)

deviation_links <- link_audit[
  link_audit$page == "result" &
    grepl("preregistration_deviations[.]html#", link_audit$href),
  ,
  drop = FALSE
]
companion_deviation_link <- link_audit[
  link_audit$page == "companion" &
    grepl("H02[.]html#h02-preregistration-deviations", link_audit$href),
  ,
  drop = FALSE
]
add_check(
  "deviation_links",
  nrow(deviation_links) == 22L &&
    length(unique(deviation_links$fragment)) == 18L &&
    all(deviation_links$resolved) &&
    nrow(companion_deviation_link) == 1L &&
    companion_deviation_link$resolved[[1L]],
  sprintf(
    "result=%d/%d unique; companion=%d",
    nrow(deviation_links),
    length(unique(deviation_links$fragment)),
    nrow(companion_deviation_link)
  )
)

registry <- utils::read.csv(
  file.path(root, "config/site_display_registry.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8"
)
companion_text <- xml_text(companion_main)
add_check(
  "country_coded_sites",
  all(vapply(
    registry$display_name,
    grepl,
    logical(1),
    x = companion_text,
    fixed = TRUE
  )),
  paste(registry$display_name, collapse = "; ")
)

manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H02/H02_preparation_report_manifest.csv"
)
manifest <- utils::read.csv(manifest_path, check.names = FALSE)
manifest_files <- file.path(root, manifest$path)
manifest_sha <- unname(vapply(manifest_files, artifact_sha256, character(1)))
manifest_bytes <- as.numeric(file.info(manifest_files)$size)
add_check(
  "preparation_manifest_live_exact",
  nrow(manifest) == 59L &&
    !anyDuplicated(manifest$path) &&
    identical(manifest_sha, unname(manifest$sha256)) &&
    identical(manifest_bytes, as.numeric(manifest$bytes)) &&
    any(
      manifest$path == "scripts/hypotheses/H02/h02_contract.R" &
        manifest$sha256 ==
          "48fef63abda50e1189b019254d56d588d539c40a984fde66502ec468878c72f0"
    ),
  sprintf("rows=%d", nrow(manifest))
)

worker_path <- file.path(
  root,
  "artifacts/12_manifests/H02/H02_worker_output_hashes.csv"
)
worker <- utils::read.csv(worker_path, check.names = FALSE)
worker_files <- file.path(root, worker$path)
worker_exists <- file.exists(worker_files)
worker_sha <- rep(NA_character_, nrow(worker))
worker_bytes <- rep(NA_real_, nrow(worker))
worker_sha[worker_exists] <- unname(vapply(
  worker_files[worker_exists],
  artifact_sha256,
  character(1)
))
worker_bytes[worker_exists] <- as.numeric(file.info(worker_files[worker_exists])$size)
worker_mismatch <- sort(worker$path[
  !worker_exists |
    worker_sha != worker$sha256 |
    worker_bytes != worker$bytes
])
expected_worker_mismatch <- sort(c(
  "_build/nathealth/notebooks/hypotheses/H02.html",
  "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html",
  "audit/handoffs/H02_shared_change_request.md",
  "audit/hypotheses/H02/H02_analysis_preparation.qmd",
  "notebooks/hypotheses/H02.qmd",
  "scripts/hypotheses/H02/build_h02_preparation_report_manifest.R",
  "scripts/hypotheses/H02/h02_contract.R",
  "artifacts/12_manifests/H02/H02_preparation_report_manifest.csv",
  "tests/hypotheses/H02/test_h02_paired_placement_display.R",
  "tests/hypotheses/H02/test_h02_preparation_report.R",
  "tests/hypotheses/H02/test_h02_reader_report.R"
))
add_check(
  "historical_worker_mismatch",
  identical(worker_mismatch, expected_worker_mismatch),
  paste(worker_mismatch, collapse = "; ")
)

pre_build <- utils::read.csv(
  file.path(evidence_dir, "build_inventory_pre.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
pre_files <- pre_build[pre_build$type == "file", , drop = FALSE]
current_paths <- list.files(
  build_root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
)
current_paths <- current_paths[file_test("-f", current_paths)]
current_relative <- substring(current_paths, nchar(build_root) + 2L)
current <- data.frame(
  path = current_relative,
  sha256 = unname(vapply(current_paths, artifact_sha256, character(1))),
  bytes = as.numeric(file.info(current_paths)$size),
  stringsAsFactors = FALSE
)
common <- intersect(pre_files$path, current$path)
pre_index <- match(common, pre_files$path)
current_index <- match(common, current$path)
changed <- common[
  pre_files$sha256[pre_index] != current$sha256[current_index] |
    pre_files$bytes[pre_index] != current$bytes[current_index]
]
missing <- setdiff(pre_files$path, current$path)
added <- setdiff(current$path, pre_files$path)
expected_changed <- sort(c(
  "audit/hypotheses/H02/H02_analysis_preparation.html",
  "audit/hypotheses/H02/H02_analysis_preparation.qmd",
  "search.json",
  "sitemap.xml"
))
expected_added <- sort(c(
  paste0(
    "artifacts/11_source_data/H02/",
    "preparation_response_distribution_exact_zero_summary.csv"
  ),
  paste0(
    "artifacts/11_source_data/H02/",
    "preparation_response_distribution_positive_observations.csv"
  )
))
add_check(
  "build_delta",
  identical(sort(changed), expected_changed) &&
    identical(sort(added), expected_added) &&
    length(missing) == 0L,
  sprintf(
    "changed=%s; added=%s; missing=%d",
    paste(sort(changed), collapse = "; "),
    paste(sort(added), collapse = "; "),
    length(missing)
  )
)

build_delta <- rbind(
  data.frame(path = sort(changed), change = "changed", stringsAsFactors = FALSE),
  data.frame(path = sort(added), change = "added", stringsAsFactors = FALSE)
)
build_delta$classification <- ifelse(
  grepl("H02_analysis_preparation[.]html$", build_delta$path),
  "companion_target_html",
  ifelse(
    grepl("H02_analysis_preparation[.]qmd$", build_delta$path),
    "source_identical_build_qmd",
    ifelse(
      build_delta$path == "search.json",
      "normal_search_update",
      ifelse(
        build_delta$path == "sitemap.xml",
        "normal_sitemap_update",
        "source_identical_download"
      )
    )
  )
)

utils::write.csv(
  record,
  file.path(evidence_dir, "order39b_nonvisual_checks.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
utils::write.csv(
  link_audit,
  file.path(evidence_dir, "order39b_link_audit.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
utils::write.csv(
  build_delta,
  file.path(evidence_dir, "order39b_build_delta_classification.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

cat(sprintf(
  "ORDER39B_NONVISUAL=PASS checks=%d links=%d internal=%d tables=16 figures=4 mermaid=1\n",
  nrow(record),
  nrow(link_audit),
  sum(link_audit$kind == "internal")
))
