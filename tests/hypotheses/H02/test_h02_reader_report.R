# Standalone structural checks for the reader-facing H02 Quarto report.

suppressPackageStartupMessages({
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

html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H02.html"
)
companion_html_path <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html"
)
qmd_path <- file.path(root, "notebooks/hypotheses/H02.qmd")
companion_qmd_path <- file.path(
  root,
  "audit/hypotheses/H02/H02_analysis_preparation.qmd"
)
deviation_qmd_path <- file.path(root, "notebooks/preregistration_deviations.qmd")
builder_path <- file.path(
  root,
  "scripts/hypotheses/H02/h02_figure4_pointwise.R"
)
near_source_path <- file.path(
  root,
  "artifacts/11_source_data/H02/figure4_exact_layout_source.rds"
)
chest_source_path <- file.path(
  root,
  "artifacts/11_source_data/H02/figure4_exact_layout_source_chest.rds"
)
paired_source_path <- file.path(
  root,
  "artifacts/11_source_data/H02/paired_placement_site_curves.csv"
)
sample_counts_path <- file.path(
  root,
  "artifacts/06_model_data/H02/sample_counts.csv"
)
preparation_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H02/H02_preparation_report_manifest.csv"
)
worker_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H02/H02_worker_output_hashes.csv"
)

required <- c(
  qmd_path,
  companion_qmd_path,
  deviation_qmd_path,
  builder_path,
  near_source_path,
  chest_source_path,
  paired_source_path,
  sample_counts_path,
  preparation_manifest_path,
  worker_manifest_path,
  html_path,
  companion_html_path
)
stopifnot(all(file.exists(required)))

historical_mismatch <- function(path) {
  manifest <- utils::read.csv(path, check.names = FALSE)
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
    artifact_sha256(preparation_manifest_path),
    "afc7a2f5458628b6e5950a5539f4d7f1b5d1984ec3afb960b19c1e147c8d721b"
  ),
  identical(
    artifact_sha256(worker_manifest_path),
    "0f3a96ab08f7fed2b59eb4a45f203297483919b3067bee560c9e239693242331"
  ),
  identical(
    historical_mismatch(preparation_manifest_path),
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
    "736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9"
  ),
  identical(
    artifact_sha256(companion_html_path),
    "966f5556a637aece91ef2e2905dcfea8d0d0587ff8d4d61c47e89e9106bbc253"
  )
)

qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
qmd <- paste(qmd_lines, collapse = "\n")
semantic_qmd_lines <- sub(
  "^[[:space:]]*>[[:space:]]?",
  "",
  qmd_lines,
  perl = TRUE
)
semantic_qmd <- gsub(
  "[[:space:]]+",
  " ",
  paste(semantic_qmd_lines, collapse = "\n"),
  perl = TRUE
)

remove_fenced_code <- function(lines) {
  in_fence <- FALSE
  visible_lines <- character()
  for (line in lines) {
    if (grepl("^[[:space:]]*```", line, perl = TRUE)) {
      in_fence <- !in_fence
    } else if (!in_fence) {
      visible_lines <- c(visible_lines, line)
    }
  }
  stopifnot(!in_fence)
  paste(visible_lines, collapse = "\n")
}

reader_visible_prose <- remove_fenced_code(qmd_lines)
companion_qmd <- paste(
  readLines(companion_qmd_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
deviation_qmd <- paste(
  readLines(deviation_qmd_path, warn = FALSE, encoding = "UTF-8"),
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
  "tbl-h02-near-variation",
  "tbl-h02-near-dominance",
  "tbl-h02-near-relevance",
  "tbl-h02-near-windows",
  "tbl-h02-chest-variation",
  "tbl-h02-chest-dominance",
  "tbl-h02-chest-relevance",
  "tbl-h02-chest-windows",
  "tbl-h02-near-diagnostics",
  "tbl-h02-chest-diagnostics",
  "tbl-h02-sensitivity",
  "tbl-h02-near-sample",
  "tbl-h02-chest-sample",
  "tbl-h02-model-deviations",
  "tbl-h02-data-deviations"
)
expected_figures <- c(
  "fig-h02-near-patterns",
  "fig-h02-chest-patterns",
  "fig-h02-paired-placement-curves",
  "fig-h02-near-diagnostics",
  "fig-h02-chest-diagnostics"
)
stopifnot(
  identical(extract_labels(qmd, "tbl"), expected_tables),
  identical(extract_labels(qmd, "fig"), expected_figures),
  !anyDuplicated(expected_tables),
  !anyDuplicated(expected_figures)
)

expected_registration_anchors <- c(
  "dev-001", "rep-001", "rep-002", "dev-012", "dev-012", "dev-011",
  "dev-010", "dev-011", "dev-021", "imp-005", "dev-012", "imp-015",
  "dev-019", "dev-057", "imp-017", "dev-021", "dev-005", "imp-012",
  "rep-003", "imp-002", "dev-049", "dev-050"
)
registration_links <- regmatches(
  qmd,
  gregexpr(
    "\\[[A-Z]{3}-[0-9]{3}\\]\\(\\.\\./preregistration_deviations\\.qmd#[a-z0-9-]+\\)",
    qmd,
    perl = TRUE
  )
)[[1L]]
registration_anchors <- sub(".*#([a-z0-9-]+)\\)$", "\\1", registration_links)
stopifnot(
  identical(registration_anchors, expected_registration_anchors),
  length(registration_anchors) == 22L,
  length(unique(registration_anchors)) == 18L,
  all(vapply(
    unique(registration_anchors),
    function(anchor) grepl(paste0("{#", anchor, "}"), deviation_qmd, fixed = TRUE),
    logical(1)
  ))
)

stopifnot(
  grepl("lightbox: true", qmd, fixed = TRUE),
  grepl(
    "../../audit/hypotheses/H02/H02_analysis_preparation.qmd",
    qmd,
    fixed = TRUE
  ),
  grepl(
    "../../../notebooks/hypotheses/H02.qmd",
    companion_qmd,
    fixed = TRUE
  ),
  grepl(
    "../../../notebooks/hypotheses/H02.qmd#h02-preregistration-deviations",
    companion_qmd,
    fixed = TRUE
  ),
  grepl(
    "### Deviations from preregistration {#h02-preregistration-deviations}",
    qmd,
    fixed = TRUE
  ),
  grepl("Show linked registration entries by topic", qmd, fixed = TRUE),
  grepl("Show detailed near-eye model checks", qmd, fixed = TRUE),
  grepl("Show detailed chest model checks", qmd, fixed = TRUE),
  !grepl("\\]\\([^)]*[.]html(?:#|\\))", qmd, perl = TRUE),
  !grepl("file://", qmd, fixed = TRUE),
  !grepl("_build", qmd, fixed = TRUE),
  !grepl("/Users/", qmd, fixed = TRUE),
  !grepl("\\]\\(/", qmd, perl = TRUE)
)

stopifnot(
  grepl("p_value_display.R", qmd, fixed = TRUE),
  grepl("gap-timing-unaware dataset", qmd, fixed = TRUE),
  grepl("paired_placement_site_curves.csv", qmd, fixed = TRUE),
  grepl("false-discovery-rate (FDR)-adjusted", qmd, fixed = TRUE),
  grepl("FDR adjustment", qmd, fixed = TRUE),
  !grepl("\\bBH\\b", qmd, perl = TRUE),
  !grepl("H02-F1-site-pattern", qmd, fixed = TRUE),
  !grepl("—", gsub('missing_text = "—"', "", qmd, fixed = TRUE), fixed = TRUE),
  !grepl(
    "format(site_test$p_adjusted, scientific = TRUE",
    qmd,
    fixed = TRUE
  )
)

stopifnot(
  grepl(
    paste(
      "Within-participant variance in hourly melanopic EDI, with",
      "participants nested in sites, exceeds variance between sites."
    ),
    semantic_qmd,
    fixed = TRUE
  ),
  grepl('s(time_hour, bs = "cc", k = 12)', qmd, fixed = TRUE),
  grepl('s(time_hour, site, bs = "sz", k = 12)', qmd, fixed = TRUE),
  grepl('s(time_hour, participant, bs = "fs", k = 10)', qmd, fixed = TRUE),
  grepl('s(participant_day, bs = "re")', qmd, fixed = TRUE),
  grepl("global time effect", tolower(qmd), fixed = TRUE),
  !grepl("equal-site", tolower(qmd), fixed = TRUE),
  !grepl("equal site", tolower(qmd), fixed = TRUE),
  !grepl("alternative preparation", tolower(qmd), fixed = TRUE)
)

sample_counts <- utils::read.csv(sample_counts_path, check.names = FALSE)
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
  nrow(near_counts) == 1L,
  nrow(chest_counts) == 1L,
  identical(as.integer(near_counts$participants), 141L),
  identical(as.integer(near_counts$participant_days), 816L),
  identical(as.integer(near_counts$observations_30_minute), 37756L),
  identical(as.integer(near_counts$sites), 9L),
  identical(as.integer(chest_counts$participants), 154L),
  identical(as.integer(chest_counts$participant_days), 902L),
  identical(as.integer(chest_counts$observations_30_minute), 41842L),
  identical(as.integer(chest_counts$sites), 8L)
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
executable_r <- paste(chunk_text, collapse = "\n")
forbidden_calls <- c(
  "mgcv::gam", "mgcv::bam", "h02_fit_bam", "predict", "simulate",
  "boot", "h02_bootstrap_variation", "run_h02_dominance_analysis"
)
stopifnot(all(!vapply(
  forbidden_calls,
  function(call) grepl(paste0(call, "[[:space:]]*\\("), executable_r, perl = TRUE),
  logical(1)
)))

for (term in c("v0", "submitted", "manuscript", "legacy", "pilot")) {
  stopifnot(!grepl(term, tolower(reader_visible_prose), fixed = TRUE))
}

protected_code_only_names <- c(
  "manuscript_prepared_stability.csv",
  "manuscript_prepared_data__glasses__all_available"
)
stopifnot(
  all(vapply(
    protected_code_only_names,
    grepl,
    logical(1),
    x = qmd,
    fixed = TRUE
  )),
  all(!vapply(
    protected_code_only_names,
    grepl,
    logical(1),
    x = reader_visible_prose,
    fixed = TRUE
  ))
)

expected_near_days <- c(
  RISE = 78L,
  THUAS = 78L,
  BAUA = 107L,
  MPI = 150L,
  TUM = 60L,
  FUSPCEU = 129L,
  IZTECH = 101L,
  UCR = 32L,
  KNUST = 81L
)
expected_chest_days <- c(
  RISE = 96L,
  THUAS = 93L,
  BAUA = 114L,
  TUM = 60L,
  FUSPCEU = 123L,
  IZTECH = 102L,
  UCR = 230L,
  KNUST = 84L
)

check_site_days <- function(source_path, expected, total) {
  source <- readRDS(source_path)
  observed <- stats::setNames(
    as.integer(source$site_solar$fitted_participant_days),
    source$site_solar$site
  )
  stopifnot(
    identical(observed, expected),
    sum(observed) == total,
    source$participant_days == total
  )
}
check_site_days(near_source_path, expected_near_days, 816L)
check_site_days(chest_source_path, expected_chest_days, 902L)

builder <- paste(readLines(builder_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("panel_c_sample_labels <- contract$site_solar", builder, fixed = TRUE),
  grepl("data = panel_c_sample_labels", builder, fixed = TRUE),
  grepl("format(.data$fitted_participant_days", builder, fixed = TRUE),
  grepl('" participant-days (d)"', builder, fixed = TRUE),
  grepl('" d"', builder, fixed = TRUE),
  grepl("x = 15", builder, fixed = TRUE),
  grepl("y = 0.28", builder, fixed = TRUE),
  grepl("hjust = 0.5", builder, fixed = TRUE),
  grepl("Site / global time effect", builder, fixed = TRUE),
  !grepl("equal-site", tolower(builder), fixed = TRUE),
  grepl('tag_levels = list(c("A", "C", "B", "D"))', builder, fixed = TRUE)
)

if (!source_only) {
  document <- xml2::read_html(html_path)
  main <- xml2::xml_find_first(
    document,
    "//main[@id='quarto-document-content']"
  )
  stopifnot(!inherits(main, "xml_missing"))

  main_text <- xml2::xml_text(main)
  main_text_lower <- tolower(main_text)
  preparation_links <- xml2::xml_find_all(
    main,
    ".//a[contains(@href, 'H02_analysis_preparation.html')]"
  )
  stale_preparation_links <- xml2::xml_find_all(
    main,
    ".//a[contains(@href, 'H02_analysis_preparation.qmd')]"
  )
  stopifnot(
    length(preparation_links) == 1L,
    length(stale_preparation_links) == 0L,
    grepl("141 participants", main_text, fixed = TRUE),
    grepl("816 participant-days", main_text, fixed = TRUE),
    grepl("37,756 30-minute", main_text, fixed = TRUE),
    grepl("154 participants", main_text, fixed = TRUE),
    grepl("902 participant-days", main_text, fixed = TRUE),
    grepl("41,842 30-minute", main_text, fixed = TRUE),
    grepl("false-discovery-rate (FDR)-adjusted p = <0.001", main_text, fixed = TRUE),
    !grepl("BH-adjusted", main_text, fixed = TRUE),
    !grepl("H02-F1-site-pattern", main_text, fixed = TRUE),
    grepl("check p = 0.435", main_text, fixed = TRUE),
    grepl("check p = 0.455", main_text, fixed = TRUE),
    grepl("check p = 0.130", main_text, fixed = TRUE),
    grepl("check p = 0.115", main_text, fixed = TRUE),
    grepl("112 participants", main_text, fixed = TRUE),
    grepl("643 participant-days", main_text, fixed = TRUE),
    grepl("29,786 30-minute observations", main_text, fixed = TRUE),
    grepl("not statistical equivalence", main_text, fixed = TRUE),
    grepl("global time effect", main_text_lower, fixed = TRUE),
    !grepl("equal-site", main_text_lower, fixed = TRUE),
    !grepl("alternative preparation", main_text_lower, fixed = TRUE),
    !grepl("@fig-", main_text, fixed = TRUE),
    !grepl("@tbl-", main_text, fixed = TRUE),
    length(xml2::xml_find_all(
      document,
      "//*[@id='quarto-embedded-source-code']"
    )) == 0L
  )

  for (id in c(expected_tables, expected_figures)) {
    stopifnot(
      length(xml2::xml_find_all(main, paste0(".//*[@id='", id, "']"))) == 1L
    )
  }

  gt_tables <- xml2::xml_find_all(
    main,
    ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
  )
  stopifnot(length(gt_tables) == length(expected_tables))
  data_rows <- vapply(
    gt_tables,
    function(table) length(xml2::xml_find_all(table, ".//tbody/tr")),
    integer(1)
  )
  header_columns <- vapply(
    gt_tables,
    function(table) length(xml2::xml_find_all(table, ".//thead/tr[last()]/th")),
    integer(1)
  )
  stopifnot(all(data_rows <= 10L), all(header_columns <= 6L))

  caption_nodes <- xml2::xml_find_all(
    main,
    ".//figcaption[contains(@class, 'quarto-float-caption')]"
  )
  captions <- trimws(xml2::xml_text(caption_nodes))
  caption_endpoints <- vapply(
    seq_along(caption_nodes),
    function(index) {
      endpoint <- xml2::xml_find_first(
        caption_nodes[[index]],
        "ancestor::*[@id][1]"
      )
      xml2::xml_attr(endpoint, "id")
    },
    character(1)
  )
  stopifnot(
    identical(
      sort(caption_endpoints),
      sort(c(expected_tables, expected_figures))
    ),
    length(captions) == length(expected_tables) + length(expected_figures),
    all(nzchar(captions))
  )

  figure_predicate <- paste0(
    "@id='",
    expected_figures,
    "'",
    collapse = " or "
  )
  images <- xml2::xml_find_all(
    main,
    paste0(".//*[", figure_predicate, "]//img")
  )
  stopifnot(length(images) == length(expected_figures))
  image_sources <- xml2::xml_attr(images, "src")
  image_alt <- xml2::xml_attr(images, "alt")
  stopifnot(
    all(nzchar(image_alt)),
    all(!startsWith(image_sources, "/")),
    all(file.exists(file.path(dirname(html_path), image_sources)))
  )
}

message(
  if (source_only) {
    "All H02 reader-report source-only tests passed"
  } else {
    "All H02 reader-report tests passed"
  }
)
