# Standalone structural and provenance checks for the H02 preparation report.

suppressPackageStartupMessages({
  library(readr)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
stopifnot(identical(as.character(getRversion()), "4.6.1"))

source_only <- tolower(
  Sys.getenv("H02_REPORT_SOURCE_ONLY", unset = "false")
) %in% c("1", "true", "yes")

qmd_path <- file.path(
  root,
  "audit/hypotheses/H02/H02_analysis_preparation.qmd"
)
result_qmd_path <- file.path(root, "notebooks/hypotheses/H02.qmd")
html_path <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html"
)
result_html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H02.html"
)
rendered_qmd_path <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.qmd"
)
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H02/H02_preparation_report_manifest.csv"
)
worker_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H02/H02_worker_output_hashes.csv"
)
positive_source_path <- file.path(
  root,
  paste0(
    "artifacts/11_source_data/H02/",
    "preparation_response_distribution_positive_observations.csv"
  )
)
zero_source_path <- file.path(
  root,
  paste0(
    "artifacts/11_source_data/H02/",
    "preparation_response_distribution_exact_zero_summary.csv"
  )
)
sample_counts_path <- file.path(
  root,
  "artifacts/06_model_data/H02/sample_counts.csv"
)

required <- c(
  qmd_path,
  result_qmd_path,
  html_path,
  result_html_path,
  manifest_path,
  worker_manifest_path,
  positive_source_path,
  zero_source_path,
  sample_counts_path
)
if (!source_only) required <- c(required, rendered_qmd_path)
stopifnot(all(file.exists(required)))

historical_mismatch <- function(path) {
  manifest <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  files <- file.path(root, manifest$path)
  exists <- file.exists(files)
  current_sha256 <- rep(NA_character_, length(files))
  current_bytes <- rep(NA_real_, length(files))
  current_sha256[exists] <- unname(vapply(
    files[exists],
    artifact_sha256,
    character(1)
  ))
  current_bytes[exists] <- as.numeric(file.info(files[exists])$size)
  sort(manifest$path[
    !exists |
      current_sha256 != manifest$sha256 |
      current_bytes != manifest$bytes
  ])
}

stopifnot(
  identical(
    artifact_sha256(manifest_path),
    "afc7a2f5458628b6e5950a5539f4d7f1b5d1984ec3afb960b19c1e147c8d721b"
  ),
  identical(
    artifact_sha256(worker_manifest_path),
    "0f3a96ab08f7fed2b59eb4a45f203297483919b3067bee560c9e239693242331"
  ),
  identical(
    historical_mismatch(manifest_path),
    character()
  ),
  identical(
    historical_mismatch(worker_manifest_path),
    sort(c(
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
  ),
  identical(
    artifact_sha256(html_path),
    "966f5556a637aece91ef2e2905dcfea8d0d0587ff8d4d61c47e89e9106bbc253"
  ),
  identical(
    artifact_sha256(result_html_path),
    "736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9"
  ),
  identical(
    artifact_sha256(positive_source_path),
    "22dff3af0f213b3ceaed0d5ca827da4184b662ff7d0366d592b6598b56e96842"
  ),
  identical(
    artifact_sha256(zero_source_path),
    "f2cc126a168bf8d6db3c5b13b3c6fea83030b23e7fdebff882bea1eb390f31db"
  )
)

qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
qmd <- paste(qmd_lines, collapse = "\n")
qmd_collapsed <- gsub("[[:space:]]+", " ", qmd, perl = TRUE)
result_qmd <- paste(
  readLines(result_qmd_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)

extract_labels <- function(text, type) {
  values <- regmatches(
    text,
    gregexpr(
      paste0("(?<=#\\| label: )", type, "-h02-[a-z0-9-]+"),
      text,
      perl = TRUE
    )
  )[[1L]]
  values[values != ""]
}

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
stopifnot(
  identical(extract_labels(qmd, "tbl"), expected_tables),
  identical(extract_labels(qmd, "fig"), expected_figures),
  !anyDuplicated(expected_tables),
  !anyDuplicated(expected_figures)
)

stopifnot(
  grepl("flowchart TD", qmd, fixed = TRUE),
  grepl("## About this analysis record", qmd, fixed = TRUE),
  grepl("## Render boundary", qmd, fixed = TRUE),
  grepl(
    "A **model frame** is the exact set of rows and variables used for one fitted model",
    qmd_collapsed,
    fixed = TRUE
  ),
  grepl("lightbox: true", qmd, fixed = TRUE),
  grepl("global time effect", qmd, fixed = TRUE),
  grepl("h02_validate_inputs(root)", qmd, fixed = TRUE),
  grepl("run_h02_analysis.R", qmd, fixed = TRUE),
  grepl("run_h02_dominance_analysis.R", qmd, fixed = TRUE),
  grepl("../../../notebooks/hypotheses/H02.qmd", qmd, fixed = TRUE),
  grepl(
    "../../../notebooks/hypotheses/H02.qmd#h02-preregistration-deviations",
    qmd,
    fixed = TRUE
  ),
  grepl(
    "../../audit/hypotheses/H02/H02_analysis_preparation.qmd",
    result_qmd,
    fixed = TRUE
  ),
  !grepl("\\]\\([^)]*[.]html(?:#|\\))", qmd, perl = TRUE),
  !grepl("file://", qmd, fixed = TRUE),
  !grepl("_build", qmd, fixed = TRUE),
  !grepl("/Users/", qmd, fixed = TRUE),
  !grepl("\\]\\(/", qmd, perl = TRUE)
)

stopifnot(
  grepl("H02_worker_output_hashes.csv", qmd, fixed = TRUE),
  grepl("p_value_display.R", qmd, fixed = TRUE),
  grepl("gap-timing-unaware dataset", qmd, fixed = TRUE),
  grepl('title.position = "top"', qmd, fixed = TRUE),
  grepl('barwidth = grid::unit(9, "cm")', qmd, fixed = TRUE),
  grepl("::: {.callout-note", qmd, fixed = TRUE),
  !grepl("::: {.callout-important", qmd, fixed = TRUE),
  grepl("response_distribution_positive", qmd, fixed = TRUE),
  grepl(
    "preparation_response_distribution_positive_observations.csv",
    qmd,
    fixed = TRUE
  ),
  grepl(
    "preparation_response_distribution_exact_zero_summary.csv",
    qmd,
    fixed = TRUE
  ),
  !grepl("response_source_dir", qmd, fixed = TRUE),
  !grepl("dir.create(", qmd, fixed = TRUE),
  !grepl("write_csv(", qmd, fixed = TRUE),
  !grepl("Step 3", qmd, fixed = TRUE),
  !grepl("Step 4", qmd, fixed = TRUE),
  !grepl("coordinator", qmd, ignore.case = TRUE),
  !grepl("alternative preparation", qmd, ignore.case = TRUE),
  !grepl("H02-F1-site-pattern", qmd, fixed = TRUE),
  !grepl("\\bBH\\b", qmd, perl = TRUE),
  !grepl("—", qmd, fixed = TRUE)
)

stopifnot(
  grepl("Calculated_on_render = \"Calculated when rendered\"", qmd, fixed = TRUE),
  grepl("Question_answered = \"Question answered\"", qmd, fixed = TRUE),
  grepl("Interpretive_limit = \"Interpretive limit\"", qmd, fixed = TRUE),
  grepl("Held_constant = \"Held constant\"", qmd, fixed = TRUE),
  grepl("Entry_point = \"Entry point\"", qmd, fixed = TRUE),
  grepl("Why_separate = \"Why separate\"", qmd, fixed = TRUE),
  grepl("Main_outputs = \"Main outputs\"", qmd, fixed = TRUE),
  grepl("Run_when_page_renders = \"Run when page renders\"", qmd, fixed = TRUE),
  grepl('"Verified",[[:space:]]+"Review needed"', qmd, perl = TRUE),
  grepl("FDR adjustment", qmd, fixed = TRUE),
  grepl("single confirmatory", qmd, fixed = TRUE),
  grepl("Benjamini-Hochberg false-discovery-rate", qmd, fixed = TRUE)
)

stopifnot(
  grepl('s(time_hour, bs = "cc", k = 12)', qmd, fixed = TRUE),
  grepl('s(time_hour, site, bs = "sz", k = 12)', qmd, fixed = TRUE),
  grepl('s(time_hour, participant, bs = "fs", k = 10)', qmd, fixed = TRUE),
  grepl('s(participant_day, bs = "re")', qmd, fixed = TRUE)
)

sample_counts <- readr::read_csv(
  sample_counts_path,
  show_col_types = FALSE,
  progress = FALSE
)
overall_counts <- sample_counts[sample_counts$site == "ALL_SITES", , drop = FALSE]
near_counts <- overall_counts[
  overall_counts$run_id == "main__glasses__all_available",
  ,
  drop = FALSE
]
chest_counts <- overall_counts[
  overall_counts$run_id == "main__chest__all_available",
  ,
  drop = FALSE
]
stopifnot(
  identical(as.integer(near_counts$participants), 141L),
  identical(as.integer(near_counts$participant_days), 816L),
  identical(as.integer(near_counts$observations_30_minute), 37756L),
  identical(as.integer(chest_counts$participants), 154L),
  identical(as.integer(chest_counts$participant_days), 902L),
  identical(as.integer(chest_counts$observations_30_minute), 41842L)
)

chunk_starts <- grep("^```\\{r(?:[^}]*)\\}[[:space:]]*$", qmd_lines, perl = TRUE)
chunk_text <- character(length(chunk_starts))
for (index in seq_along(chunk_starts)) {
  start <- chunk_starts[[index]]
  following <- which(
    seq_along(qmd_lines) > start & grepl("^```[[:space:]]*$", qmd_lines)
  )
  stopifnot(length(following) > 0L)
  end <- following[[1L]]
  chunk_text[[index]] <- paste(qmd_lines[(start + 1L):(end - 1L)], collapse = "\n")
}
call_head_name <- function(node) {
  if (is.symbol(node)) return(as.character(node))
  if (
    is.call(node) &&
      length(node) == 3L &&
      as.character(node[[1L]]) %in% c("::", ":::") &&
      is.symbol(node[[2L]]) &&
      is.symbol(node[[3L]])
  ) {
    return(paste0(
      as.character(node[[2L]]),
      as.character(node[[1L]]),
      as.character(node[[3L]])
    ))
  }
  NA_character_
}

collect_call_heads <- function(expression) {
  heads <- character()
  visit <- function(node) {
    if (is.expression(node) || is.pairlist(node)) {
      for (index in seq_along(node)) {
        if (identical(node[[index]], quote(expr = ))) next
        visit(node[[index]])
      }
      return(invisible(NULL))
    }
    if (!is.call(node)) return(invisible(NULL))
    head <- call_head_name(node[[1L]])
    if (!is.na(head)) heads <<- c(heads, head)
    if (length(node) > 1L) {
      for (index in seq.int(2L, length(node))) {
        if (identical(node[[index]], quote(expr = ))) next
        visit(node[[index]])
      }
    }
    invisible(NULL)
  }
  visit(expression)
  heads
}

parsed_chunks <- lapply(
  chunk_text,
  function(text) parse(text = text, keep.source = TRUE)
)
actual_call_heads <- sort(unique(unlist(lapply(
  parsed_chunks,
  collect_call_heads
))))
forbidden_calls <- c(
  "mgcv::gam", "mgcv::bam", "h02_fit_bam", "predict", "simulate",
  "boot", "h02_bootstrap_variation", "h02_dominance"
)
stopifnot(
  !any(forbidden_calls %in% actual_call_heads),
  grepl("mgcv::bam()", qmd, fixed = TRUE)
)

manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
stopifnot(
  nrow(manifest) >= 35L,
  !anyDuplicated(manifest$path),
  all(nchar(manifest$sha256) == 64L),
  "_quarto-nathealth.yml" %in% manifest$path,
  "artifacts/11_source_data/H02/preparation_response_distribution_positive_observations.csv" %in%
    manifest$path,
  "artifacts/11_source_data/H02/preparation_response_distribution_exact_zero_summary.csv" %in%
    manifest$path,
  "artifacts/11_source_data/H02/paired_placement_site_curves.csv" %in%
    manifest$path,
  "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.qmd" %in%
    manifest$path,
  sum(startsWith(
    manifest$path,
    paste0(
      "_build/nathealth/audit/hypotheses/H02/",
      "H02_analysis_preparation_files/"
    )
  )) == 4L
)

if (!source_only) {
  stopifnot(identical(
    readLines(qmd_path, warn = FALSE),
    readLines(rendered_qmd_path, warn = FALSE)
  ))
  manifest_files <- file.path(root, manifest$path)
  stopifnot(all(file.exists(manifest_files)))
  actual_hashes <- unname(vapply(
    manifest_files,
    artifact_sha256,
    character(1)
  ))
  stopifnot(identical(actual_hashes, unname(manifest$sha256)))

  document <- xml2::read_html(html_path)
  main <- xml2::xml_find_first(
    document,
    "//main[@id='quarto-document-content']"
  )
  stopifnot(!inherits(main, "xml_missing"))
  main_text <- xml2::xml_text(main)
  result_links <- xml2::xml_find_all(
    main,
    ".//a[contains(@href, 'notebooks/hypotheses/H02.html')]"
  )
  stale_result_links <- xml2::xml_find_all(
    main,
    ".//a[contains(@href, 'notebooks/hypotheses/H02.qmd')]"
  )
  note_callouts <- xml2::xml_find_all(
    main,
    ".//*[contains(concat(' ', normalize-space(@class), ' '), ' callout-note ')]"
  )
  important_callouts <- xml2::xml_find_all(
    main,
    ".//*[contains(concat(' ', normalize-space(@class), ' '), ' callout-important ')]"
  )
  stopifnot(
    grepl("H02 analysis preparation and provenance", main_text, fixed = TRUE),
    grepl("37,756", main_text, fixed = TRUE),
    grepl("41,842", main_text, fixed = TRUE),
    grepl("816", main_text, fixed = TRUE),
    grepl("902", main_text, fixed = TRUE),
    grepl("global time effect", main_text, fixed = TRUE),
    grepl("gap-timing-unaware dataset", main_text, fixed = TRUE),
    grepl("FDR-adjusted p", main_text, fixed = TRUE),
    !grepl("BH-adjusted", main_text, fixed = TRUE),
    !grepl("H02-F1-site-pattern", main_text, fixed = TRUE),
    grepl("<0.001", main_text, fixed = TRUE),
    !grepl("alternative preparation", main_text, ignore.case = TRUE),
    grepl("does not fit a model", tolower(main_text), fixed = TRUE),
    !grepl("Execution halted", main_text, fixed = TRUE),
    length(result_links) >= 1L,
    length(stale_result_links) == 0L,
    length(note_callouts) >= 1L,
    length(important_callouts) == 0L
  )

  for (id in c(expected_tables, expected_figures)) {
    node <- xml2::xml_find_first(main, paste0(".//*[@id='", id, "']"))
    stopifnot(!inherits(node, "xml_missing"))
  }

  images <- xml2::xml_find_all(
    main,
    ".//img[contains(@class, 'img-fluid') or @alt]"
  )
  image_alt <- xml2::xml_attr(images, "alt")
  stopifnot(
    length(images) >= 4L,
    all(!is.na(image_alt)),
    all(nzchar(image_alt))
  )

  gt_tables <- xml2::xml_find_all(
    main,
    ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
  )
  stopifnot(length(gt_tables) >= 16L)
}

message(
  if (source_only) {
    "All H02 preparation-report source-only tests passed"
  } else {
    "All H02 preparation-report tests passed"
  }
)
