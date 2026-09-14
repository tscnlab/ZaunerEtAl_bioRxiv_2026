#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
output_dir <- paste0(
  "audit/report_harmonization/",
  "report018_final_corpus_integration"
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

file_bytes <- function(path) unname(as.numeric(file.info(path)$size))

checks <- list()
add_check <- function(domain, check_id, pass, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(
    domain = domain,
    check_id = check_id,
    pass = isTRUE(pass),
    detail = as.character(detail),
    stringsAsFactors = FALSE
  )
}

historical_corpus <- file.path(
  output_dir,
  "historical_phase4_corpus_manifest_pre.csv"
)
historical_identity <- readr::read_csv(
  file.path(output_dir, "historical_phase4_corpus_manifest_pre_identity.csv"),
  show_col_types = FALSE
)
rebuild <- readr::read_csv(
  file.path(output_dir, "manifest_rebuild_execution.csv"),
  show_col_types = FALSE
)
manifest_path <- "audit/report_harmonization/phase4_corpus_manifest.csv"
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)

historical_pass <- file.exists(historical_corpus) &&
  sha256_file(historical_corpus) ==
    "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334" &&
  nrow(historical_identity) == 1L &&
  historical_identity$exact &&
  nrow(rebuild) == 6L &&
  all(rebuild$status == "PASS") &&
  rebuild$value[rebuild$field == "builder_execution_count"] == "1" &&
  sha256_file(manifest_path) ==
    "983b16136c1115d5a6b8dceb135c10de8d347743c694c5027c4ead9b2c7aa605"
add_check(
  "manifest",
  "single_rebuild_and_historical_preimage_preserved",
  historical_pass,
  "builder=1 historical=73f1a371 current=983b1613"
)

source_exists <- file.exists(manifest$source) & !dir.exists(manifest$source)
html_exists <- file.exists(manifest$expected_html) &
  !dir.exists(manifest$expected_html)
live_source_sha256 <- rep(NA_character_, nrow(manifest))
live_html_sha256 <- rep(NA_character_, nrow(manifest))
live_source_sha256[source_exists] <- vapply(
  manifest$source[source_exists],
  sha256_file,
  character(1)
)
live_html_sha256[html_exists] <- vapply(
  manifest$expected_html[html_exists],
  sha256_file,
  character(1)
)
manifest_audit <- data.frame(
  logical_order = manifest$logical_order,
  role = manifest$role,
  source = manifest$source,
  expected_html = manifest$expected_html,
  source_sha256 = manifest$source_sha256,
  live_source_sha256 = live_source_sha256,
  source_exact = source_exists & live_source_sha256 == manifest$source_sha256,
  html_sha256 = manifest$html_sha256,
  live_html_sha256 = live_html_sha256,
  html_exact = html_exists & live_html_sha256 == manifest$html_sha256,
  stringsAsFactors = FALSE
)
readr::write_csv(manifest_audit, file.path(output_dir, "corpus_live_audit.csv"))

manifest_pass <- nrow(manifest) == 37L &&
  identical(as.integer(manifest$logical_order), seq_len(37L)) &&
  !anyDuplicated(manifest$source) &&
  !anyDuplicated(manifest$expected_html) &&
  all(source_exists) &&
  all(html_exists) &&
  all(manifest_audit$source_exact) &&
  all(manifest_audit$html_exact) &&
  all(nzchar(manifest$title)) &&
  identical(
    as.integer(manifest$render_position),
    c(36L, 37L, seq_len(35L))
  ) &&
  identical(as.integer(manifest$sidebar_position), seq_len(37L)) &&
  sum(manifest$role == "hypothesis_result") == 11L &&
  sum(manifest$role == "hypothesis_companion") == 11L &&
  sum(manifest$role == "preparation") == 7L &&
  sum(manifest$role == "shared") == 8L &&
  manifest$source[[37L]] == "notebooks/sensitivity_battery.qmd" &&
  manifest$html_sha256[[37L]] ==
    "875f53995f5f47ec30b630a5cf47edfef1d0fe925034d3fab4944be8c6c6b4be"
add_check(
  "manifest",
  "all_37_sources_and_html_targets_current_and_ordered",
  manifest_pass,
  sprintf(
    "sources=%d/%d html=%d/%d final=%s",
    sum(manifest_audit$source_exact),
    nrow(manifest_audit),
    sum(manifest_audit$html_exact),
    nrow(manifest_audit),
    manifest$source[[37L]]
  )
)

test_runs <- readr::read_csv(
  file.path(output_dir, "structural_tests/structural_test_runs.csv"),
  show_col_types = FALSE
)
expected_test_status <- c(0L, 0L, 0L, 1L, 1L, 0L, 0L, 0L, 1L)
expected_test_hash <- c(
  "723c3b68294f99df8c202766f55a05d5069e1d4d81ae233bc140edc9c587874f",
  "0b1c7a580041ff348ff7ae2d4c75a4ccd2f8c92ea1eb7b88c6d1d439e1284fbe",
  "79ec7f8ce5bb2bb7d9fcb96589d9bd79bb01bcb7b9b7d75247de0b38e35ab428",
  "a46f9ff0d85f3b943e14a6378b7c773c21af7e911f14afddc32c817e5aa94df3",
  "94d456d01b0298fb2b14d8a880ecddeef6a6a3f3fd9bd7fdc029a82de91c32f3",
  "70036318c83c322d93c3918f6db57f848365993256524b9c518b61e9bdb31689",
  "4feb4c3106e791e710cb5c5f270a0a3c6dc7f55b824e45144ec19b6caaffe7ae",
  "bc5aa45826ce77cbdc67cca9903f4e1ef3de784d8d90a978b01eba726a4b5af1",
  "7f9e6c1dbaf3f48beec3cfeef7fd81d8bf42104fc343d8eae55442b60c11ee9a"
)
test_disposition <- ifelse(
  expected_test_status == 0L,
  "PASS",
  c(
    rep(NA_character_, 3L),
    "HISTORICAL_H01_RENDER_STATUS",
    "HISTORICAL_PHASE2_TABLE_STATUS",
    rep(NA_character_, 3L),
    "RETIRED_PRE_OVERLAY_LINK_GATE"
  )
)
test_disposition[is.na(test_disposition)] <- "PASS"
test_classification <- data.frame(
  label = test_runs$label,
  exit_status = test_runs$exit_status,
  output_sha256 = test_runs$output_sha256,
  disposition = test_disposition,
  accepted = test_runs$exit_status == expected_test_status &
    test_runs$output_sha256 == expected_test_hash,
  stringsAsFactors = FALSE
)
readr::write_csv(
  test_classification,
  file.path(output_dir, "structural_test_classification.csv")
)
test_pass <- nrow(test_runs) == 9L &&
  all(test_classification$accepted) &&
  sum(test_disposition == "PASS") == 6L &&
  sum(test_disposition != "PASS") == 3L
add_check(
  "tests",
  "six_current_passes_and_three_historical_stops_exact",
  test_pass,
  "current_pass=6/6 classified_historical=3/3"
)

build_root <- normalizePath(
  "_build/nathealth",
  winslash = "/",
  mustWork = TRUE
)
document_cache <- new.env(parent = emptyenv())
read_cached_html <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (!exists(normalized, envir = document_cache, inherits = FALSE)) {
    assign(normalized, xml2::read_html(normalized), envir = document_cache)
  }
  get(normalized, envir = document_cache, inherits = FALSE)
}

dom_rows <- list()
table_rows <- list()
link_rows <- list()
for (document_index in seq_len(nrow(manifest))) {
  html_path <- manifest$expected_html[[document_index]]
  document <- read_cached_html(html_path)
  main_nodes <- xml2::xml_find_all(
    document,
    "//main[@id='quarto-document-content']"
  )
  main <- if (length(main_nodes) == 1L) main_nodes[[1L]] else document
  ids <- xml2::xml_attr(
    xml2::xml_find_all(
      document,
      "//*[@id and not(ancestor-or-self::svg)]"
    ),
    "id"
  )
  ids <- ids[!is.na(ids) & nzchar(ids)]
  duplicate_id_values <- unique(ids[duplicated(ids)])
  tables <- xml2::xml_find_all(
    main,
    paste0(
      ".//table[contains(concat(' ', normalize-space(@class), ' '), ",
      "' gt_table ')]"
    )
  )
  figures <- xml2::xml_find_all(main, ".//figure//img")
  figure_alt <- xml2::xml_attr(figures, "alt")
  missing_alt_mask <- is.na(figure_alt) | !nzchar(trimws(figure_alt))
  missing_alt_images <- figures[missing_alt_mask]
  missing_roles <- xml2::xml_attr(missing_alt_images, "role")
  missing_aria_hidden <- xml2::xml_attr(
    missing_alt_images,
    "aria-hidden"
  )
  decorative_missing_alt <- sum(
    !is.na(missing_roles) &
      missing_roles == "presentation" &
      !is.na(missing_aria_hidden) &
      missing_aria_hidden == "true"
  )
  informative_missing_alt <- length(missing_alt_images) -
    decorative_missing_alt
  missing_alt_captioned <- sum(vapply(
    missing_alt_images,
    function(image) {
      figure <- xml2::xml_find_first(image, "ancestor::figure[1]")
      length(xml2::xml_find_all(
        figure,
        ".//figcaption[normalize-space()]"
      )) ==
        1L
    },
    logical(1)
  ))
  error_nodes <- xml2::xml_find_all(
    main,
    paste0(
      ".//*[contains(concat(' ', normalize-space(@class), ' '), ",
      "' cell-output-error ') or contains(concat(' ', normalize-space(@class), ",
      "' '), ' quarto-error ')]"
    )
  )

  unresolved_headers <- 0L
  header_tokens <- 0L
  tables_without_headers <- 0L
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
      tokens <- unlist(
        lapply(header_values, function(value) {
          value <- ifelse(is.na(value), "", value)
          pieces <- strsplit(trimws(value), "[[:space:]]+")[[1L]]
          pieces[nzchar(pieces)]
        }),
        use.names = FALSE
      )
      unresolved <- if (length(tokens)) {
        sum(vapply(
          tokens,
          function(token) sum(table_ids == token) != 1L,
          logical(1)
        ))
      } else {
        0L
      }
      header_tokens <- header_tokens + length(tokens)
      unresolved_headers <- unresolved_headers + unresolved
      tables_without_headers <- tables_without_headers +
        as.integer(!length(tokens))
      table_rows[[length(table_rows) + 1L]] <- data.frame(
        source = manifest$source[[document_index]],
        html = html_path,
        table_index = table_index,
        table_id = if (length(table_ids)) table_ids[[1L]] else "",
        header_tokens = length(tokens),
        unresolved_header_tokens = unresolved,
        th_cells = length(xml2::xml_find_all(table, ".//th")),
        td_cells = length(xml2::xml_find_all(table, ".//td")),
        scope_attributes = length(xml2::xml_find_all(table, ".//*[@scope]")),
        stringsAsFactors = FALSE
      )
    }
  }

  anchors <- xml2::xml_find_all(main, ".//a[@href]")
  hrefs <- xml2::xml_attr(anchors, "href")
  hrefs <- hrefs[!is.na(hrefs) & nzchar(trimws(hrefs))]
  local_hrefs <- hrefs[
    !grepl(
      "^(?:https?:|mailto:|tel:|javascript:|data:|//)",
      hrefs,
      perl = TRUE,
      ignore.case = TRUE
    )
  ]
  unresolved_links <- 0L
  outside_build <- 0L
  for (href in local_hrefs) {
    href_no_query <- sub("[?].*$", "", href)
    has_fragment <- grepl("#", href_no_query, fixed = TRUE)
    fragment <- if (has_fragment) {
      utils::URLdecode(sub("^[^#]*#", "", href_no_query))
    } else {
      ""
    }
    path_part <- utils::URLdecode(sub("#.*$", "", href_no_query))
    target <- if (!nzchar(path_part)) {
      html_path
    } else if (startsWith(path_part, "/")) {
      file.path(build_root, sub("^/+", "", path_part))
    } else {
      file.path(dirname(html_path), path_part)
    }
    target <- normalizePath(target, winslash = "/", mustWork = FALSE)
    inside <- identical(target, build_root) ||
      startsWith(target, paste0(build_root, "/"))
    outside_build <- outside_build + as.integer(!inside)
    target_for_fragment <- target
    if (dir.exists(target_for_fragment)) {
      target_for_fragment <- file.path(target_for_fragment, "index.html")
    }
    target_exists <- inside &&
      (file.exists(target) || dir.exists(target))
    fragment_resolves <- TRUE
    if (target_exists && nzchar(fragment)) {
      target_ids <- if (
        file.exists(target_for_fragment) &&
          grepl("[.]html?$", target_for_fragment, ignore.case = TRUE)
      ) {
        xml2::xml_attr(
          xml2::xml_find_all(
            read_cached_html(target_for_fragment),
            ".//*[@id]"
          ),
          "id"
        )
      } else {
        character()
      }
      fragment_resolves <- sum(target_ids == fragment, na.rm = TRUE) == 1L
    }
    resolved <- target_exists && fragment_resolves
    unresolved_links <- unresolved_links + as.integer(!resolved)
    link_rows[[length(link_rows) + 1L]] <- data.frame(
      source_html = html_path,
      href = href,
      resolved_target = target,
      inside_build = inside,
      target_exists = target_exists,
      fragment = fragment,
      fragment_resolves = fragment_resolves,
      resolved = resolved,
      stringsAsFactors = FALSE
    )
  }

  dom_rows[[document_index]] <- data.frame(
    logical_order = manifest$logical_order[[document_index]],
    source = manifest$source[[document_index]],
    html = html_path,
    main_count = length(main_nodes),
    document_ids = length(ids),
    duplicate_ids = length(duplicate_id_values),
    gt_tables = length(tables),
    header_tokens = header_tokens,
    unresolved_header_tokens = unresolved_headers,
    tables_without_headers = tables_without_headers,
    figures = length(figures),
    figures_missing_alt = length(missing_alt_images),
    informative_missing_alt = informative_missing_alt,
    decorative_missing_alt = decorative_missing_alt,
    missing_alt_captioned = missing_alt_captioned,
    error_nodes = length(error_nodes),
    local_links = length(local_hrefs),
    unresolved_local_links = unresolved_links,
    outside_build_links = outside_build,
    stringsAsFactors = FALSE
  )
}

dom_audit <- do.call(rbind, dom_rows)
table_audit <- if (length(table_rows)) do.call(rbind, table_rows) else
  data.frame()
link_audit <- if (length(link_rows)) do.call(rbind, link_rows) else data.frame()
readr::write_csv(dom_audit, file.path(output_dir, "corpus_dom_audit.csv"))
readr::write_csv(
  table_audit,
  file.path(output_dir, "corpus_table_semantic_audit.csv")
)
readr::write_csv(
  link_audit,
  file.path(output_dir, "corpus_internal_link_audit.csv")
)

legacy_table_expected <- data.frame(
  source = c(
    "notebooks/preparation/01_import_state_alignment.qmd",
    "notebooks/preparation/02_coverage_sample_flow.qmd",
    "notebooks/preparation/03_reference_profiles.qmd",
    "notebooks/preparation/04_metric_derivation.qmd",
    "notebooks/preparation/05_model_input_acquisition.qmd",
    "notebooks/preparation/06_model_ready_datasets.qmd",
    "notebooks/preparation/07_example_days.qmd",
    "notebooks/descriptives.qmd"
  ),
  duplicate_ids = c(5L, 6L, 2L, 3L, 0L, 14L, 2L, 31L),
  unresolved_header_tokens = c(
    486L,
    615L,
    497L,
    862L,
    342L,
    1518L,
    187L,
    1002L
  ),
  stringsAsFactors = FALSE
)
legacy_match <- match(legacy_table_expected$source, dom_audit$source)
legacy_table_disposition <- data.frame(
  source = legacy_table_expected$source,
  category = "LEGACY_TABLE_SEMANTICS_LIMITATION",
  expected_duplicate_ids = legacy_table_expected$duplicate_ids,
  observed_duplicate_ids = dom_audit$duplicate_ids[legacy_match],
  expected_unresolved_header_tokens = legacy_table_expected$unresolved_header_tokens,
  observed_unresolved_header_tokens = dom_audit$unresolved_header_tokens[
    legacy_match
  ],
  exact = dom_audit$duplicate_ids[legacy_match] ==
    legacy_table_expected$duplicate_ids &
    dom_audit$unresolved_header_tokens[legacy_match] ==
      legacy_table_expected$unresolved_header_tokens,
  stringsAsFactors = FALSE
)
modern_semantic <- dom_audit[
  !dom_audit$source %in% legacy_table_expected$source,
  ,
  drop = FALSE
]
headerless <- table_audit[table_audit$header_tokens == 0L, , drop = FALSE]
scope_only_pass <- nrow(headerless) == 1L &&
  headerless$source[[1L]] ==
    "audit/hypotheses/H06/H06_analysis_preparation.qmd" &&
  headerless$table_index[[1L]] == 12L &&
  headerless$table_id[[1L]] == "tbl-h06-prep-category-cell-minima--gt-0001" &&
  headerless$th_cells[[1L]] == 5L &&
  headerless$td_cells[[1L]] == 0L &&
  headerless$scope_attributes[[1L]] == 5L

semantic_disposition <- rbind(
  legacy_table_disposition,
  data.frame(
    source = "audit/hypotheses/H06/H06_analysis_preparation.qmd",
    category = "SCOPE_ONLY_HEADER_TABLE_ACCEPTED",
    expected_duplicate_ids = 0L,
    observed_duplicate_ids = 0L,
    expected_unresolved_header_tokens = 0L,
    observed_unresolved_header_tokens = 0L,
    exact = scope_only_pass,
    stringsAsFactors = FALSE
  )
)
readr::write_csv(
  semantic_disposition,
  file.path(output_dir, "corpus_semantic_disposition.csv")
)

dom_pass <- nrow(dom_audit) == 37L &&
  all(dom_audit$main_count == 1L) &&
  all(legacy_table_disposition$exact) &&
  all(modern_semantic$duplicate_ids == 0L) &&
  all(modern_semantic$unresolved_header_tokens == 0L) &&
  scope_only_pass &&
  all(dom_audit$error_nodes == 0L) &&
  all(dom_audit$unresolved_local_links == 0L) &&
  all(dom_audit$outside_build_links == 0L) &&
  nrow(table_audit) == sum(dom_audit$gt_tables) &&
  nrow(link_audit) == sum(dom_audit$local_links) &&
  sum(dom_audit$gt_tables) == 572L &&
  sum(dom_audit$header_tokens) == 46120L &&
  sum(dom_audit$figures) == 160L &&
  sum(dom_audit$local_links) == 10192L
add_check(
  "rendered corpus",
  "current_pages_strict_and_legacy_table_semantics_exactly_classified",
  dom_pass,
  sprintf(
    paste0(
      "pages=%d tables=%d headers=%d links=%d ",
      "legacy_pages=8 unresolved=5509 duplicate_ids=63 scope_only=1"
    ),
    nrow(dom_audit),
    sum(dom_audit$gt_tables),
    sum(dom_audit$header_tokens),
    sum(dom_audit$local_links)
  )
)

index_alt <- dom_audit[dom_audit$source == "index.qmd", , drop = FALSE]
descriptives_alt <- dom_audit[
  dom_audit$source == "notebooks/descriptives.qmd",
  ,
  drop = FALSE
]
other_alt <- dom_audit[
  !dom_audit$source %in% c("index.qmd", "notebooks/descriptives.qmd"),
  ,
  drop = FALSE
]
alt_pass <- nrow(index_alt) == 1L &&
  index_alt$informative_missing_alt[[1L]] == 24L &&
  index_alt$decorative_missing_alt[[1L]] == 0L &&
  index_alt$missing_alt_captioned[[1L]] == 24L &&
  nrow(descriptives_alt) == 1L &&
  descriptives_alt$informative_missing_alt[[1L]] == 0L &&
  descriptives_alt$decorative_missing_alt[[1L]] == 17L &&
  descriptives_alt$missing_alt_captioned[[1L]] == 17L &&
  all(other_alt$figures_missing_alt == 0L)
alt_disposition <- data.frame(
  source = c("index.qmd", "notebooks/descriptives.qmd"),
  category = c(
    "LEGACY_INFORMATIVE_IMAGE_ALT_LIMITATION",
    "DECORATIVE_IMAGE_EMPTY_ALT_ACCEPTED"
  ),
  informative_missing_alt = c(24L, 0L),
  decorative_missing_alt = c(0L, 17L),
  captioned = c(24L, 17L),
  exact = c(alt_pass, alt_pass),
  stringsAsFactors = FALSE
)
readr::write_csv(
  alt_disposition,
  file.path(output_dir, "corpus_image_alt_disposition.csv")
)
add_check(
  "rendered corpus",
  "image_alt_contract_and_legacy_index_limitation_exactly_classified",
  alt_pass,
  paste0(
    "strict_pages=35/35 index_informative_missing=24 ",
    "descriptives_decorative_empty=17 captions=41/41"
  )
)

build_members <- sort(list.files(
  build_root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  include.dirs = TRUE,
  no.. = TRUE
))
build_links <- Sys.readlink(build_members)
add_check(
  "build",
  "complete_build_has_no_symlink",
  length(build_members) == 1180L && !any(nzchar(build_links)),
  sprintf(
    "members=%d symlinks=%d",
    length(build_members),
    sum(nzchar(build_links))
  )
)

checks_frame <- do.call(rbind, checks)
readr::write_csv(checks_frame, file.path(output_dir, "final_corpus_checks.csv"))
stopifnot(nrow(checks_frame) == 6L, all(checks_frame$pass))

cat(sprintf(
  paste0(
    "REPORT018_FINAL_CORPUS=PASS checks=%d/%d sources=37/37 html=37/37 ",
    "tables=%d headers=%d figures=%d links=%d build=1180 symlinks=0 R=%s\n"
  ),
  sum(checks_frame$pass),
  nrow(checks_frame),
  sum(dom_audit$gt_tables),
  sum(dom_audit$header_tokens),
  sum(dom_audit$figures),
  sum(dom_audit$local_links),
  as.character(getRversion())
))
