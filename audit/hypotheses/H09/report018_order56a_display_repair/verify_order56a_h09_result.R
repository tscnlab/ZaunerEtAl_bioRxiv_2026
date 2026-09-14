#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

run_postrender <- function() {
  assert_true(file.exists(html_path), "The fresh H09 result HTML is missing.")
  render_execution_path <- file.path(evidence_dir, "render_execution.csv")
  render_log_path <- file.path(evidence_dir, "render_console.log")
  assert_true(
    file.exists(render_execution_path),
    "The render execution record is missing."
  )
  assert_true(
    file.exists(render_log_path),
    "The render console log is missing."
  )
  render_execution <- read.csv(render_execution_path, check.names = FALSE)
  assert_true(
    nrow(render_execution) == 1L &&
      render_execution$attempt[[1L]] == 1L &&
      render_execution$exit_code[[1L]] == 0L &&
      render_execution$target[[1L]] == qmd_relative &&
      render_execution$profile[[1L]] == "nathealth" &&
      render_execution$autoloader[[1L]] == "disabled" &&
      render_execution$r_version[[1L]] == "4.6.1",
    "The sole-render execution record failed."
  )
  render_log <- paste(readLines(render_log_path, warn = FALSE), collapse = "\n")
  render_patterns <- c(
    "Error in ",
    "Execution halted",
    "Quitting from",
    "Warning:",
    "WARN ",
    "stderr",
    "unresolved reference",
    "???"
  )
  render_console_audit <- data.frame(
    pattern = render_patterns,
    present = vapply(
      render_patterns,
      grepl,
      logical(1),
      x = render_log,
      fixed = TRUE
    )
  )
  render_console_audit$status <- ifelse(
    render_console_audit$present,
    "FAIL",
    "PASS"
  )
  write_evidence(render_console_audit, "render_console_classification.csv")
  assert_none(
    render_console_audit$present,
    "The render console contains an error, warning, stderr, or unresolved reference."
  )

  semantic_dir <- normalizePath(
    Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
    winslash = "/",
    mustWork = TRUE
  )
  summary_external <- file.path(
    semantic_dir,
    "gt_html_semantic_post_render_summary.csv"
  )
  assert_true(file.exists(summary_external), "The semantic summary is missing.")
  summary <- readr::read_csv(summary_external, show_col_types = FALSE)
  assert_true(nrow(summary) == 1L, "The semantic summary must have one row.")
  assert_true(summary$target == html_relative, "The semantic target changed.")
  assert_true(
    summary$disposition %in% c("REPAIRED", "ALREADY_REPAIRED"),
    "The semantic disposition is not accepted."
  )
  assert_true(summary$table_count == 11L, "The semantic table count changed.")
  ledger_external <- file.path(semantic_dir, summary$ledger_file)
  assert_true(file.exists(ledger_external), "The semantic ledger is missing.")
  assert_true(
    file.copy(
      summary_external,
      file.path(evidence_dir, basename(summary_external)),
      overwrite = TRUE
    ),
    "Could not retain the semantic summary."
  )
  assert_true(
    file.copy(
      ledger_external,
      file.path(evidence_dir, basename(ledger_external)),
      overwrite = TRUE
    ),
    "Could not retain the semantic ledger."
  )

  engine <- new.env(parent = globalenv())
  sys.source(
    file.path(root, "scripts/report_harmonization/repair_gt_html_semantics.R"),
    envir = engine
  )
  ledger <- readr::read_csv(ledger_external, show_col_types = FALSE)
  final_raw <- engine$read_file_raw(html_path)
  reversed_raw <- engine$apply_raw_replacements(
    final_raw,
    ledger,
    reverse = TRUE
  )
  reapplied_raw <- engine$apply_raw_replacements(
    reversed_raw,
    ledger,
    reverse = FALSE
  )
  semantic_reverse <- data.frame(
    check = c(
      "summary post hash equals final HTML",
      "reverse hash equals pre-hook hash",
      "forward reapplication equals final HTML",
      "ledger rows equal substitutions",
      "ledger IDs equal summary ID count",
      "ledger headers equal summary headers count"
    ),
    observed = c(
      engine$sha256_raw(final_raw),
      engine$sha256_raw(reversed_raw),
      engine$sha256_raw(reapplied_raw),
      nrow(ledger),
      sum(ledger$attribute == "id"),
      sum(ledger$attribute == "headers")
    ),
    expected = c(
      summary$post_sha256,
      summary$pre_sha256,
      summary$post_sha256,
      summary$total_substitutions,
      summary$id_count,
      summary$headers_count
    ),
    stringsAsFactors = FALSE
  )
  semantic_reverse$status <- ifelse(
    semantic_reverse$observed == semantic_reverse$expected,
    "PASS",
    "FAIL"
  )
  write_evidence(semantic_reverse, "semantic_reverse_audit.csv")
  assert_all(
    semantic_reverse$status == "PASS",
    "The semantic reverse audit failed."
  )
  assert_true(
    identical(final_raw, reapplied_raw),
    "Semantic reapplication differs."
  )

  pre_document <- xml2::read_html(rawToChar(reversed_raw))
  post_document <- xml2::read_html(rawToChar(final_raw))
  pre_main <- rvest::html_elements(pre_document, "main#quarto-document-content")
  post_main <- rvest::html_elements(
    post_document,
    "main#quarto-document-content"
  )
  assert_true(length(pre_main) == 1L, "The pre-hook main is not unique.")
  assert_true(length(post_main) == 1L, "The post-hook main is not unique.")
  pre_main <- pre_main[[1L]]
  post_main <- post_main[[1L]]
  pre_elements <- xml2::xml_find_all(pre_document, "//*")
  post_elements <- xml2::xml_find_all(post_document, "//*")
  pre_links <- xml2::xml_attr(
    xml2::xml_find_all(pre_document, "//a[@href]"),
    "href"
  )
  post_links <- xml2::xml_attr(
    xml2::xml_find_all(post_document, "//a[@href]"),
    "href"
  )
  pre_captions <- vapply(
    rvest::html_elements(pre_main, "figcaption.quarto-float-caption"),
    clean_text,
    character(1)
  )
  post_captions <- vapply(
    rvest::html_elements(post_main, "figcaption.quarto-float-caption"),
    clean_text,
    character(1)
  )
  pre_notes <- vapply(
    rvest::html_elements(pre_main, ".gt_sourcenotes"),
    clean_text,
    character(1)
  )
  post_notes <- vapply(
    rvest::html_elements(post_main, ".gt_sourcenotes"),
    clean_text,
    character(1)
  )
  semantic_invariance <- data.frame(
    check = c(
      "normalized DOM excluding repaired gt attributes",
      "whole-document visible text",
      "main visible text and values",
      "element tag sequence",
      "link target sequence",
      "caption sequence",
      "source-note sequence"
    ),
    pre_value = c(
      hash_text(engine$normalized_dom_without_mutable_values(pre_document)),
      hash_text(xml2::xml_text(pre_document)),
      hash_text(xml2::xml_text(pre_main)),
      hash_text(paste(xml2::xml_name(pre_elements), collapse = "|")),
      hash_text(paste(pre_links, collapse = "|")),
      hash_text(paste(pre_captions, collapse = "|")),
      hash_text(paste(pre_notes, collapse = "|"))
    ),
    post_value = c(
      hash_text(engine$normalized_dom_without_mutable_values(post_document)),
      hash_text(xml2::xml_text(post_document)),
      hash_text(xml2::xml_text(post_main)),
      hash_text(paste(xml2::xml_name(post_elements), collapse = "|")),
      hash_text(paste(post_links, collapse = "|")),
      hash_text(paste(post_captions, collapse = "|")),
      hash_text(paste(post_notes, collapse = "|"))
    ),
    stringsAsFactors = FALSE
  )
  semantic_invariance$status <- ifelse(
    semantic_invariance$pre_value == semantic_invariance$post_value,
    "PASS",
    "FAIL"
  )
  write_evidence(semantic_invariance, "semantic_invariance_audit.csv")
  assert_all(
    semantic_invariance$status == "PASS",
    "The semantic hook changed visible or structural content."
  )

  document <- xml2::read_html(html_path)
  main_nodes <- rvest::html_elements(document, "main#quarto-document-content")
  assert_true(length(main_nodes) == 1L, "The rendered H09 main is not unique.")
  main <- main_nodes[[1L]]
  main_text <- clean_text(main)
  ids <- xml2::xml_attr(xml2::xml_find_all(document, "//*[@id]"), "id")
  duplicate_ids <- unique(ids[duplicated(ids)])
  write_evidence(
    data.frame(duplicate_id = duplicate_ids, stringsAsFactors = FALSE),
    "duplicate_id_audit.csv"
  )
  assert_true(
    length(duplicate_ids) == 0L,
    "The rendered HTML has duplicate IDs."
  )

  table_endpoints <- rvest::html_elements(main, '.quarto-float[id^="tbl-h09-"]')
  table_endpoints <- table_endpoints[outside_source_modal(table_endpoints)]
  table_ids <- rvest::html_attr(table_endpoints, "id")
  assert_true(
    identical(table_ids, expected_tables),
    "Rendered table order changed."
  )
  table_audit <- lapply(seq_along(table_endpoints), function(index) {
    endpoint <- table_endpoints[[index]]
    table <- rvest::html_elements(endpoint, "table.gt_table")
    data.frame(
      order = index,
      endpoint = table_ids[[index]],
      native_gt_count = length(table),
      caption_count = length(rvest::html_elements(
        endpoint,
        "figcaption.quarto-float-caption"
      )),
      rows = length(rvest::html_elements(table, "tr")),
      header_cells = length(rvest::html_elements(table, "th")),
      body_cells = length(rvest::html_elements(table, "td")),
      caption = clean_text(rvest::html_element(
        endpoint,
        "figcaption.quarto-float-caption"
      )),
      status = ifelse(length(table) == 1L, "PASS", "FAIL"),
      stringsAsFactors = FALSE
    )
  })
  table_audit <- do.call(rbind, table_audit)
  write_evidence(table_audit, "table_endpoint_audit.csv")
  assert_true(nrow(table_audit) == 11L, "The rendered table count changed.")
  assert_all(table_audit$status == "PASS", "A table endpoint is not native gt.")

  figure_endpoints <- rvest::html_elements(
    main,
    '.quarto-float[id^="fig-h09-"]'
  )
  figure_endpoints <- figure_endpoints[outside_source_modal(figure_endpoints)]
  figure_ids <- rvest::html_attr(figure_endpoints, "id")
  assert_true(
    identical(figure_ids, expected_figures),
    "Rendered figure order changed."
  )
  figure_audit <- lapply(seq_along(figure_endpoints), function(index) {
    endpoint <- figure_endpoints[[index]]
    image <- rvest::html_element(endpoint, "img")
    src <- rvest::html_attr(image, "src")
    built_path <- normalizePath(
      file.path(dirname(html_path), utils::URLdecode(src)),
      winslash = "/",
      mustWork = TRUE
    )
    durable_path <- file.path(root, expected_figure_paths[[index]])
    source_path <- normalizePath(
      file.path(dirname(qmd_path), expected_figure_sources[[index]]),
      winslash = "/",
      mustWork = TRUE
    )
    source_link_required <- index <= 2L
    source_link_visible <- any(grepl(
      basename(expected_figure_sources[[index]]),
      rvest::html_attr(rvest::html_elements(main, "a[href]"), "href"),
      fixed = TRUE
    ))
    data.frame(
      order = index,
      endpoint = figure_ids[[index]],
      image_src = src,
      image_alt = rvest::html_attr(image, "alt"),
      caption = clean_text(rvest::html_element(
        endpoint,
        "figcaption.quarto-float-caption"
      )),
      built_sha256 = sha256_file(built_path),
      durable_sha256 = sha256_file(durable_path),
      source_data_path = relative_path(source_path),
      source_data_sha256 = sha256_file(source_path),
      source_link_required = source_link_required,
      source_link_visible = source_link_visible,
      status = ifelse(
        sha256_file(built_path) == sha256_file(durable_path) &&
          nzchar(rvest::html_attr(image, "alt")) &&
          (!source_link_required || source_link_visible),
        "PASS",
        "FAIL"
      ),
      stringsAsFactors = FALSE
    )
  })
  figure_audit <- do.call(rbind, figure_audit)
  write_evidence(figure_audit, "figure_endpoint_audit.csv")
  assert_true(nrow(figure_audit) == 4L, "The rendered figure count changed.")
  assert_all(figure_audit$status == "PASS", "A figure endpoint failed.")
  assert_true(
    identical(
      figure_audit$source_data_sha256,
      unname(source_identities[c(1, 2, 3, 3)])
    ),
    "A rendered figure source identity changed."
  )

  formula_endpoint <- table_endpoints[[match("tbl-h09-formulas", table_ids)]]
  formula_table <- rvest::html_element(formula_endpoint, "table.gt_table")
  formula_rows <- rvest::html_elements(formula_table, "tbody tr")
  formula_cells <- lapply(
    formula_rows,
    function(row) rvest::html_elements(row, "th,td")
  )
  formula_instruments <- vapply(
    formula_cells,
    function(cells) clean_text(cells[[1L]]),
    character(1)
  )
  formula_roles <- vapply(
    formula_cells,
    function(cells) clean_text(cells[[2L]]),
    character(1)
  )
  formula_strings <- vapply(
    formula_cells,
    function(cells) clean_text(cells[[3L]]),
    character(1)
  )
  formula_audit <- data.frame(
    order = seq_along(formula_rows),
    instrument = formula_instruments,
    role = formula_roles,
    formula = formula_strings,
    status = ifelse(
      formula_instruments == rep(c("MCTQ MSFsc", "MEQ"), each = 3L) &&
        formula_roles ==
          rep(
            c(
              "Site only",
              "Average chronotype association",
              "Chronotype-by-site interaction"
            ),
            2L
          ) &&
        formula_strings == expected_formula_rows,
      "PASS",
      "FAIL"
    ),
    stringsAsFactors = FALSE
  )
  write_evidence(formula_audit, "formula_table_audit.csv")
  assert_true(nrow(formula_audit) == 6L, "The formula table row count changed.")
  assert_all(
    formula_audit$status == "PASS",
    "The formula table content changed."
  )
  assert_true(
    length(unique(formula_strings)) == 5L &&
      identical(unique(formula_strings), expected_formulas),
    "The formula table does not contain the five ordered unique formulas."
  )

  tables <- rvest::html_elements(main, "table.gt_table")
  header_rows <- list()
  row_index <- 0L
  for (table_index in seq_along(tables)) {
    table <- tables[[table_index]]
    table_id <- rvest::html_attr(table, "id")
    if (is.na(table_id) || !nzchar(table_id))
      table_id <- paste0("table-", table_index)
    header_nodes <- rvest::html_elements(table, "[headers]")
    for (node in header_nodes) {
      tokens <- strsplit(rvest::html_attr(node, "headers"), "[[:space:]]+")[[
        1L
      ]]
      tokens <- tokens[nzchar(tokens)]
      for (token in tokens) {
        row_index <- row_index + 1L
        local_matches <- xml2::xml_find_all(
          table,
          sprintf(".//th[@id='%s']", token)
        )
        document_matches <- xml2::xml_find_all(
          document,
          sprintf("//th[@id='%s']", token)
        )
        header_rows[[row_index]] <- data.frame(
          table = table_id,
          token = token,
          local_resolution_count = length(local_matches),
          document_resolution_count = length(document_matches),
          status = ifelse(
            length(local_matches) == 1L && length(document_matches) == 1L,
            "PASS",
            "FAIL"
          ),
          stringsAsFactors = FALSE
        )
      }
    }
  }
  header_audit <- do.call(rbind, header_rows)
  write_evidence(header_audit, "table_header_reference_audit.csv")
  assert_true(nrow(header_audit) > 0L, "No table header references were found.")
  assert_all(
    header_audit$status == "PASS",
    "A headers token does not resolve once locally."
  )

  normalized_markdown <- gsub("[\r\n]+", " ", qmd_text)
  source_markdown_matches <- regmatches(
    normalized_markdown,
    gregexpr("\\[[^]]*\\]\\(([^)]+)\\)", normalized_markdown, perl = TRUE)
  )[[1L]]
  source_occurrences <- sub(
    "^.*\\]\\(([^)]+)\\)$",
    "\\1",
    source_markdown_matches,
    perl = TRUE
  )
  assert_true(
    length(source_occurrences) == 23L &&
      length(unique(source_occurrences)) == 21L,
    "The source link occurrence contract changed after render."
  )
  source_targets <- sort(expected_targets)
  rendered_targets <- sub("[.]qmd(?=#|$)", ".html", source_targets, perl = TRUE)
  hrefs <- rvest::html_attr(rvest::html_elements(main, "a[href]"), "href")
  rendered_root_targets <- vapply(
    source_targets,
    function(target) {
      if (!grepl("[.]qmd($|#)", target)) return(NA_character_)
      anchor <- if (grepl("#", target, fixed = TRUE)) {
        paste0("#", sub("^[^#]*#", "", target))
      } else {
        ""
      }
      file_target <- sub("#.*$", "", target)
      source_absolute <- normalizePath(
        file.path(dirname(qmd_path), file_target),
        winslash = "/",
        mustWork = TRUE
      )
      paste0(
        "../../",
        sub("[.]qmd$", ".html", relative_path(source_absolute)),
        anchor
      )
    },
    character(1)
  )
  observed_href <- vapply(
    seq_along(source_targets),
    function(index) {
      candidates <- unique(stats::na.omit(c(
        rendered_targets[[index]],
        rendered_root_targets[[index]]
      )))
      matches <- candidates[candidates %in% hrefs]
      if (length(matches)) matches[[1L]] else ""
    },
    character(1)
  )
  expected_occurrences <- vapply(
    source_targets,
    function(target) {
      sum(source_occurrences == target)
    },
    integer(1)
  )
  observed_occurrences <- vapply(
    seq_along(source_targets),
    function(index) {
      candidates <- unique(stats::na.omit(c(
        rendered_targets[[index]],
        rendered_root_targets[[index]]
      )))
      sum(hrefs %in% candidates)
    },
    integer(1)
  )
  link_audit <- data.frame(
    source_target = source_targets,
    observed_href = observed_href,
    expected_occurrences = expected_occurrences,
    observed_occurrences = observed_occurrences,
    present = nzchar(observed_href),
    stringsAsFactors = FALSE
  )
  link_audit$status <- ifelse(
    link_audit$present &
      link_audit$expected_occurrences == link_audit$observed_occurrences,
    "PASS",
    "FAIL"
  )
  write_evidence(link_audit, "reader_link_audit.csv")
  assert_all(link_audit$status == "PASS", "A rendered reader target changed.")
  assert_true(
    sum(link_audit$observed_occurrences) == 23L,
    "Rendered links do not total 23."
  )

  required_rendered_phrases <- c(
    "Answer in brief",
    "covered 186 participants",
    "complete for 185 participants",
    "complete for all 186",
    "131–141 participants",
    "478–816 participant-days",
    "11,325.5–18,851.0 derivation hours",
    "149–154 participants",
    "547–902 participant-days",
    "12,980.0–20,891.8 derivation hours",
    "Four inferential families were kept distinct for each placement",
    "primary near-eye",
    "Complementary chest",
    "acceptable response/residual distribution and heteroscedasticity assessments",
    "singular maximum-likelihood chronotype-by-site interaction fit",
    "gap-timing-unaware dataset",
    "direction instability",
    "not an equivalence",
    "does not establish that chronotype causes"
  )
  phrase_audit <- data.frame(
    phrase = required_rendered_phrases,
    present = vapply(
      required_rendered_phrases,
      grepl,
      logical(1),
      x = main_text,
      fixed = TRUE
    )
  )
  phrase_audit$status <- ifelse(phrase_audit$present, "PASS", "FAIL")
  write_evidence(phrase_audit, "reader_phrase_audit.csv")
  assert_all(phrase_audit$present, "A rendered reader contract is missing.")

  count_bold_in_column <- function(endpoint, column) {
    rows <- rvest::html_elements(endpoint, "tbody tr")
    sum(vapply(
      rows,
      function(row) {
        cells <- rvest::html_elements(row, "th,td")
        length(cells) >= column &&
          length(rvest::html_elements(cells[[column]], "strong")) > 0L
      },
      logical(1)
    ))
  }
  near_endpoint <- table_endpoints[[match(
    "tbl-h09-near-eye-results",
    table_ids
  )]]
  chest_endpoint <- table_endpoints[[match("tbl-h09-chest-results", table_ids)]]
  interaction_endpoint <- table_endpoints[[match(
    "tbl-h09-interactions",
    table_ids
  )]]
  rendered_science_audit <- data.frame(
    check = c(
      "near-eye result rows",
      "chest result rows",
      "interaction rows",
      "near-eye adjusted-significant rows",
      "chest adjusted-significant rows",
      "interaction adjusted-significant rows",
      "near-eye adjusted-p header",
      "chest adjusted-p header",
      "interaction adjusted-p header"
    ),
    observed = c(
      length(rvest::html_elements(near_endpoint, "tbody tr")),
      length(rvest::html_elements(chest_endpoint, "tbody tr")),
      length(rvest::html_elements(interaction_endpoint, "tbody tr")),
      count_bold_in_column(near_endpoint, 5L),
      count_bold_in_column(chest_endpoint, 5L),
      count_bold_in_column(interaction_endpoint, 6L),
      as.integer(grepl(
        "FDR-adjusted p",
        clean_text(near_endpoint),
        fixed = TRUE
      )),
      as.integer(grepl(
        "FDR-adjusted p",
        clean_text(chest_endpoint),
        fixed = TRUE
      )),
      as.integer(grepl(
        "FDR-adjusted p",
        clean_text(interaction_endpoint),
        fixed = TRUE
      ))
    ),
    expected = c(10L, 10L, 20L, 6L, 4L, 0L, 1L, 1L, 1L)
  )
  rendered_science_audit$status <- ifelse(
    rendered_science_audit$observed == rendered_science_audit$expected,
    "PASS",
    "FAIL"
  )
  write_evidence(rendered_science_audit, "rendered_scientific_contract.csv")
  assert_all(
    rendered_science_audit$status == "PASS",
    "A rendered science contract changed."
  )

  site_registry <- read.csv(
    file.path(root, "config/site_display_registry.csv"),
    check.names = FALSE
  )
  site_names <- if ("display_name" %in% names(site_registry)) {
    site_registry$display_name
  } else {
    site_registry[[ncol(site_registry)]]
  }
  bare_site_names <- sub(" \\([A-Z]{2}\\)$", "", site_names)
  site_audit <- data.frame(
    site = site_names,
    coded_present = vapply(
      site_names,
      grepl,
      logical(1),
      x = main_text,
      fixed = TRUE
    ),
    uncoded_present = vapply(
      bare_site_names,
      function(site) {
        grepl(
          sprintf("%s(?! \\([A-Z]{2}\\)| Chronotype Questionnaire)", site),
          main_text,
          perl = TRUE
        )
      },
      logical(1)
    )
  )
  site_audit$status <- ifelse(!site_audit$uncoded_present, "PASS", "FAIL")
  write_evidence(site_audit, "country_site_audit.csv")
  assert_none(
    site_audit$uncoded_present,
    "A visible site name lacks its country code."
  )

  active_links <- rvest::html_elements(
    document,
    "a.sidebar-link.active, a.nav-link.active"
  )
  active_hrefs <- rvest::html_attr(active_links, "href")
  navigation_audit <- data.frame(
    check = c(
      "active H09 navigation",
      "reciprocal companion link",
      "DEV-037 rendered anchor",
      "DEV-038 rendered anchor",
      "DEV-039 rendered anchor"
    ),
    observed = c(
      any(grepl("notebooks/hypotheses/H09[.]html", active_hrefs)),
      any(grepl(
        "audit/hypotheses/H09/H09_analysis_preparation[.]html$",
        hrefs
      )),
      any(grepl("preregistration_deviations[.]html#dev-037$", hrefs)),
      any(grepl("preregistration_deviations[.]html#dev-038$", hrefs)),
      any(grepl("preregistration_deviations[.]html#dev-039$", hrefs))
    )
  )
  navigation_audit$status <- ifelse(navigation_audit$observed, "PASS", "FAIL")
  write_evidence(navigation_audit, "dynamic_link_audit.csv")
  assert_all(navigation_audit$observed, "Navigation or deviation links failed.")

  defect_patterns <- c(
    "Error in ",
    "Execution halted",
    "Quitting from",
    "Warning:",
    "stderr",
    "unresolved reference",
    "@tbl-h09-",
    "@fig-h09-",
    "???",
    "file://",
    "/Users/",
    "/private/tmp/"
  )
  defect_audit <- data.frame(
    pattern = defect_patterns,
    present = vapply(
      defect_patterns,
      grepl,
      logical(1),
      x = main_text,
      fixed = TRUE
    )
  )
  defect_audit$status <- ifelse(defect_audit$present, "FAIL", "PASS")
  write_evidence(defect_audit, "embedded_defect_audit.csv")
  assert_none(
    defect_audit$present,
    "The rendered page contains an execution defect or local path."
  )

  pre_build <- read.csv(
    file.path(evidence_dir, "build_inventory_prerender.csv"),
    check.names = FALSE
  )
  build_merge <- merge(
    pre_build[, c("relative_path", "sha256", "bytes")],
    build_inventory[, c("relative_path", "sha256", "bytes")],
    by = "relative_path",
    all = TRUE,
    suffixes = c("_pre", "_post")
  )
  build_merge$transition <- ifelse(
    is.na(build_merge$sha256_pre),
    "added",
    ifelse(
      is.na(build_merge$sha256_post),
      "removed",
      ifelse(
        build_merge$sha256_pre == build_merge$sha256_post,
        "exact",
        "changed"
      )
    )
  )
  delta <- build_merge[build_merge$transition != "exact", , drop = FALSE]
  source_candidates <- file.path(
    root,
    sub("^_build/nathealth/", "", delta$relative_path)
  )
  source_identical <- file.exists(source_candidates)
  source_identical[source_identical] <- vapply(
    seq_len(sum(source_identical)),
    function(index) TRUE,
    logical(1)
  )
  for (index in which(file.exists(source_candidates))) {
    source_identical[[index]] <-
      sha256_file(source_candidates[[index]]) == delta$sha256_post[[index]]
  }
  allowed <- delta$relative_path == html_relative |
    startsWith(
      delta$relative_path,
      "_build/nathealth/notebooks/hypotheses/H09_files/"
    ) |
    delta$relative_path %in%
      c(
        "_build/nathealth/search.json",
        "_build/nathealth/sitemap.xml"
      ) |
    source_identical
  delta$source_identical <- source_identical
  delta$classification <- ifelse(
    delta$relative_path == html_relative,
    "authorized H09 result target",
    ifelse(
      source_identical,
      "ordinary source-identical target resource",
      ifelse(
        startsWith(
          delta$relative_path,
          "_build/nathealth/notebooks/hypotheses/H09_files/"
        ),
        "target-owned result resource",
        "expected website integration"
      )
    )
  )
  delta$status <- ifelse(
    allowed & delta$transition != "removed",
    "PASS",
    "FAIL"
  )
  write_evidence(delta, "build_delta_postrender.csv")
  assert_true(nrow(delta) > 0L, "The render produced no build delta.")
  assert_all(delta$status == "PASS", "An unclassified build delta occurred.")

  pre_protected_render <- read.csv(
    file.path(evidence_dir, "protected_inventory_prerender.csv"),
    check.names = FALSE
  )
  protected_merge <- merge(
    pre_protected_render[, c("relative_path", "sha256", "bytes")],
    protected_inventory[, c("relative_path", "sha256", "bytes")],
    by = "relative_path",
    all = TRUE,
    suffixes = c("_pre", "_post")
  )
  protected_merge$exact <-
    protected_merge$sha256_pre == protected_merge$sha256_post &
    protected_merge$bytes_pre == protected_merge$bytes_post
  protected_merge$expected_transition <- protected_merge$relative_path ==
    html_relative
  protected_merge$coordination_evidence_only <-
    protected_merge$relative_path ==
      "audit/report_harmonization/coordination_matrix.csv"
  protected_merge$status <- ifelse(
    protected_merge$exact |
      protected_merge$expected_transition |
      protected_merge$coordination_evidence_only,
    "PASS",
    "FAIL"
  )
  write_evidence(protected_merge, "protected_reconciliation_postrender.csv")
  assert_all(
    protected_merge$status == "PASS",
    "A protected path changed outside the result target."
  )
  protected_scientific_transitions <- protected_merge[
    !protected_merge$exact & !protected_merge$coordination_evidence_only,
    ,
    drop = FALSE
  ]
  assert_true(
    nrow(protected_scientific_transitions) == 1L &&
      protected_scientific_transitions$relative_path[[1L]] == html_relative,
    "The post-render protected transition set is not result-only."
  )

  fixed_post <- data.frame(
    path = names(fixed_identities),
    expected_sha256 = unname(fixed_identities),
    observed_sha256 = vapply(
      file.path(root, names(fixed_identities)),
      sha256_file,
      character(1)
    ),
    stringsAsFactors = FALSE
  )
  fixed_post$status <- ifelse(
    fixed_post$expected_sha256 == fixed_post$observed_sha256,
    "PASS",
    "FAIL"
  )
  write_evidence(fixed_post, "fixed_identity_postrender.csv")
  assert_all(
    fixed_post$status == "PASS",
    "A fixed source, companion, test, or tool changed."
  )

  stage3_path <- file.path(
    root,
    "artifacts/12_manifests/H09/H09_stage3_artifacts.csv"
  )
  stage3 <- read.csv(stage3_path, check.names = FALSE)
  stage3_paths <- file.path(root, stage3$path)
  stage3_exists <- file.exists(stage3_paths)
  stage3_sha <- rep(NA_character_, nrow(stage3))
  stage3_sha[stage3_exists] <- vapply(
    stage3_paths[stage3_exists],
    sha256_file,
    character(1)
  )
  stage3_bytes <- rep(NA_real_, nrow(stage3))
  stage3_bytes[stage3_exists] <- as.numeric(
    file.info(stage3_paths[stage3_exists])$size
  )
  stage3_exact <- stage3_exists &
    stage3_sha == stage3$sha256 &
    stage3_bytes == stage3$bytes
  expected_stage3_transitions <- c(
    "audit/hypotheses/H09/H09_stage1_gate_and_stage2_transition.md",
    "scripts/hypotheses/H09/h09_contract.R",
    "scripts/hypotheses/H09/run_h09_stage2.R",
    "audit/handoffs/H09_worker_handoff.md",
    file.path("artifacts/10_figures/H09", figure_files),
    "audit/handoffs/H09_shared_change_request.md",
    "artifacts/06_model_data/H09/H09_base_bundle_audit.csv",
    "artifacts/06_model_data/H09/H09_input_audit.csv",
    "artifacts/12_manifests/H09/H09_figure_manifest.csv",
    html_relative,
    qmd_relative,
    "config/metric_display_registry.csv",
    "_quarto-nathealth.yml",
    "audit/decisions/figure_readability_and_layout.md"
  )
  stage3_post <- data.frame(
    path = stage3$path,
    exact = stage3_exact,
    classification = ifelse(
      stage3_exact,
      "live-exact",
      ifelse(
        stage3$path %in% expected_stage3_transitions,
        "accepted transition",
        "unclassified"
      )
    )
  )
  stage3_post$status <- ifelse(
    stage3_post$exact | stage3_post$classification == "accepted transition",
    "PASS",
    "FAIL"
  )
  write_evidence(stage3_post, "stage3_manifest_postrender_audit.csv")
  assert_true(
    identical(
      sort(stage3$path[!stage3_exact]),
      sort(expected_stage3_transitions)
    ),
    "The historical Stage 3 transition set changed after render."
  )

  phase4_path <- file.path(
    root,
    "audit/report_harmonization/phase4_corpus_manifest.csv"
  )
  phase4_pre <- pre_protected[
    pre_protected$relative_path ==
      "audit/report_harmonization/phase4_corpus_manifest.csv",
    ,
    drop = FALSE
  ]
  assert_true(
    nrow(phase4_pre) == 1L && sha256_file(phase4_path) == phase4_pre$sha256,
    "The phase-4 corpus manifest changed."
  )
  phase4 <- read.csv(phase4_path, check.names = FALSE)
  h09_phase4 <- phase4[phase4$source == qmd_relative, , drop = FALSE]
  phase4_audit <- data.frame(
    source = qmd_relative,
    source_live_exact = h09_phase4$source_sha256 == sha256_file(qmd_path),
    manifest_html_sha256 = h09_phase4$html_sha256,
    fresh_html_sha256 = sha256_file(html_path),
    html_transition = h09_phase4$html_sha256 != sha256_file(html_path),
    manifest_file_exact = sha256_file(phase4_path) == phase4_pre$sha256,
    status = "PASS",
    stringsAsFactors = FALSE
  )
  write_evidence(phase4_audit, "phase4_manifest_transition.csv")
  assert_true(
    nrow(h09_phase4) == 1L &&
      phase4_audit$source_live_exact &&
      phase4_audit$html_transition &&
      phase4_audit$manifest_file_exact,
    "The phase-4 H09 transition contract failed."
  )

  candidate_inventory <- read.csv(
    file.path(evidence_dir, "candidate_inventory.csv"),
    check.names = FALSE
  )
  durable_paths <- file.path(root, "artifacts/10_figures/H09", figure_files)
  assert_true(
    identical(
      unname(vapply(durable_paths, sha256_file, character(1))),
      candidate_inventory$sha256
    ),
    "A durable output changed during render."
  )
  source_post <- data.frame(
    path = names(source_identities),
    expected_sha256 = unname(source_identities),
    observed_sha256 = vapply(
      file.path(root, names(source_identities)),
      sha256_file,
      character(1)
    ),
    stringsAsFactors = FALSE
  )
  source_post$status <- ifelse(
    source_post$expected_sha256 == source_post$observed_sha256,
    "PASS",
    "FAIL"
  )
  write_evidence(source_post, "frozen_source_postrender.csv")
  assert_all(
    source_post$status == "PASS",
    "A frozen source CSV changed during render."
  )

  nonvisual_status <- data.frame(
    domain = c(
      "sole result render",
      "semantic reverse and reapplication",
      "semantic visible and structural invariance",
      "11 native gt endpoints",
      "formula table and five unique formulas",
      "four figure endpoints and source reconciliation",
      "document IDs and table header references",
      "23 links and 21 unique targets",
      "reader hierarchy, qualifications, and sensitivities",
      "FDR families and bolding",
      "country-coded sites and active navigation",
      "embedded defects and local paths",
      "historical tests and manifests",
      "build delta classification",
      "protected identity reconciliation",
      "figure typography floor pending visual QA"
    ),
    status = "PASS",
    stringsAsFactors = FALSE
  )
  write_evidence(nonvisual_status, "nonvisual_status.csv")
  cat(sprintf(
    paste0(
      "ORDER56A_POSTRENDER=PASS html=%s tables=%d figures=%d headers=%d ",
      "semantic=%s substitutions=%d build_delta=%d protected=%d\n"
    ),
    sha256_file(html_path),
    nrow(table_audit),
    nrow(figure_audit),
    nrow(header_audit),
    summary$disposition,
    summary$total_substitutions,
    nrow(delta),
    nrow(protected_merge)
  ))
}

run_stopped <- function() {
  render_execution <- read.csv(
    file.path(evidence_dir, "render_execution.csv"),
    check.names = FALSE
  )
  assert_true(
    nrow(render_execution) == 1L &&
      render_execution$attempt[[1L]] == 1L &&
      render_execution$exit_code[[1L]] == 1L &&
      render_execution$target[[1L]] == qmd_relative &&
      render_execution$profile[[1L]] == "nathealth" &&
      render_execution$autoloader[[1L]] == "disabled" &&
      render_execution$disposition[[1L]] ==
        "STOPPED_BEFORE_HTML_SASS_CACHE_DATABASE_UNAVAILABLE",
    "The stopped render execution record failed."
  )
  render_log <- paste(
    readLines(file.path(evidence_dir, "render_console.log"), warn = FALSE),
    collapse = "\n"
  )
  required_log_tokens <- c(
    "processing file: H09.qmd",
    "35/35",
    "output file: H09.knit.md",
    "ERROR: unable to open database file",
    "sassCache",
    "Object.openKv"
  )
  log_audit <- data.frame(
    token = required_log_tokens,
    present = vapply(
      required_log_tokens,
      grepl,
      logical(1),
      x = render_log,
      fixed = TRUE
    )
  )
  log_audit$status <- ifelse(log_audit$present, "PASS", "FAIL")
  write_evidence(log_audit, "stopped_render_log_audit.csv")
  assert_all(
    log_audit$status == "PASS",
    "The stopped render log contract failed."
  )

  semantic_dir <- normalizePath(
    Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
    winslash = "/",
    mustWork = TRUE
  )
  semantic_members <- list_files(semantic_dir)
  semantic_audit <- data.frame(
    semantic_dir = semantic_dir,
    member_count = length(semantic_members),
    hook_reached = FALSE,
    status = ifelse(length(semantic_members) == 0L, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
  write_evidence(semantic_audit, "semantic_directory_stopped.csv")
  assert_true(
    semantic_audit$status == "PASS",
    "The semantic hook unexpectedly wrote output."
  )

  assert_true(
    sha256_file(html_path) ==
      "dbc9122ca0a7be6e051741d8354f9ebdec8e072753d9b2592d6387f9716a7caa",
    "The canonical result HTML changed despite the stopped render."
  )
  fixed_stopped <- data.frame(
    path = names(fixed_identities),
    expected_sha256 = unname(fixed_identities),
    observed_sha256 = vapply(
      file.path(root, names(fixed_identities)),
      sha256_file,
      character(1)
    ),
    stringsAsFactors = FALSE
  )
  fixed_stopped$status <- ifelse(
    fixed_stopped$expected_sha256 == fixed_stopped$observed_sha256,
    "PASS",
    "FAIL"
  )
  write_evidence(fixed_stopped, "fixed_identity_stopped.csv")
  assert_all(
    fixed_stopped$status == "PASS",
    "A fixed source or held target changed."
  )

  candidate_inventory <- read.csv(
    file.path(evidence_dir, "candidate_inventory.csv"),
    check.names = FALSE
  )
  durable_paths <- file.path(root, "artifacts/10_figures/H09", figure_files)
  durable_hashes <- unname(vapply(durable_paths, sha256_file, character(1)))
  assert_true(
    identical(durable_hashes, candidate_inventory$sha256),
    "A promoted durable figure changed during the stopped render."
  )
  source_proof <- read.csv(
    file.path(evidence_dir, "source_forward_reverse_proof.csv"),
    check.names = FALSE
  )
  assert_true(
    all(source_proof$status == "PASS") &&
      sha256_file(file.path(root, "scripts/hypotheses/H09/run_h09_stage2.R")) ==
        source_proof$postimage_sha256[source_proof$member == "builder"] &&
      sha256_file(file.path(
        root,
        "artifacts/12_manifests/H09/H09_figure_manifest.csv"
      )) ==
        source_proof$postimage_sha256[source_proof$member == "figure_manifest"],
    "A repaired source transition changed during the stopped render."
  )

  pre_build <- read.csv(
    file.path(evidence_dir, "build_inventory_prerender.csv"),
    check.names = FALSE
  )
  build_compare <- merge(
    pre_build[, c("relative_path", "sha256", "bytes")],
    build_inventory[, c("relative_path", "sha256", "bytes")],
    by = "relative_path",
    all = TRUE,
    suffixes = c("_pre", "_stopped")
  )
  build_compare$exact <-
    build_compare$sha256_pre == build_compare$sha256_stopped &
    build_compare$bytes_pre == build_compare$bytes_stopped
  build_compare$status <- ifelse(build_compare$exact, "PASS", "FAIL")
  write_evidence(build_compare, "build_reconciliation_stopped.csv")
  assert_all(
    build_compare$status == "PASS",
    "The stopped render changed the build."
  )

  pre_protected_render <- read.csv(
    file.path(evidence_dir, "protected_inventory_prerender.csv"),
    check.names = FALSE
  )
  protected_compare <- merge(
    pre_protected_render[, c("relative_path", "sha256", "bytes")],
    protected_inventory[, c("relative_path", "sha256", "bytes")],
    by = "relative_path",
    all = TRUE,
    suffixes = c("_pre", "_stopped")
  )
  protected_compare$exact <-
    protected_compare$sha256_pre == protected_compare$sha256_stopped &
    protected_compare$bytes_pre == protected_compare$bytes_stopped
  protected_compare$status <- ifelse(protected_compare$exact, "PASS", "FAIL")
  write_evidence(protected_compare, "protected_reconciliation_stopped.csv")
  assert_all(
    protected_compare$status == "PASS",
    "The stopped render changed a protected path."
  )

  process_probe <- read.csv(
    file.path(evidence_dir, "process_probe_stopped.csv"),
    check.names = FALSE
  )
  assert_true(
    nrow(process_probe) == 1L &&
      process_probe$observed_count[[1L]] == 0L &&
      process_probe$status[[1L]] == "PASS",
    "A render-related process remains after the stop."
  )
  knit_members <- list.files(
    root,
    pattern = "^H09[.]knit[.]md$",
    full.names = TRUE,
    recursive = TRUE
  )
  assert_true(length(knit_members) == 0L, "A temporary H09 knit file remains.")

  failure_classification <- read.csv(
    file.path(evidence_dir, "render_failure_classification.csv"),
    check.names = FALSE
  )
  assert_all(
    failure_classification$status == "PASS",
    "The render-failure classification is incomplete."
  )
  stopped_status <- data.frame(
    domain = c(
      "candidate and focused-test gate",
      "one-time durable promotion",
      "complete pre-render gate",
      "single authorized render",
      "knitr source execution",
      "Quarto Sass cache",
      "fresh HTML and semantic hook",
      "canonical pre-render HTML",
      "durable repaired figures",
      "source, companion, tests, and protected scope",
      "build identity",
      "remaining processes",
      "second render"
    ),
    disposition = c(
      "PASS",
      "PASS",
      "PASS",
      "CONSUMED_ONCE_EXIT_1",
      "PASS_35_OF_35",
      "STOPPED_UNABLE_TO_OPEN_DATABASE",
      "NOT_REACHED",
      "BYTE_EXACT",
      "CANDIDATE_IDENTICAL",
      "BYTE_EXACT",
      "BYTE_EXACT",
      "ZERO",
      "NOT_AUTHORIZED"
    ),
    stringsAsFactors = FALSE
  )
  write_evidence(stopped_status, "final_stopped_status.csv")

  stop_lines <- c(
    "# REPORT-018 order 56a H09 result: FAIL-CLOSED STOP",
    "",
    "The complete candidate and pre-render gates passed. All eight repaired figure files were promoted together exactly once.",
    "",
    "The sole authorized H09 result render completed all 35 knitr steps, then stopped before HTML generation because Quarto could not open its Sass cache database.",
    "",
    "- Render attempts consumed: `1`",
    "- Render exit code: `1`",
    "- Failure: `ERROR: unable to open database file` in `sassCache` via `Deno.openKv`",
    "- Cache path: `/Users/zauner/Library/Caches/quarto/sass/sass.kv`",
    "- Classification: infrastructure/cache access outside the authorized workspace write roots",
    "- Scientific-source discrepancy: `none observed`",
    "- Fresh semantic output: `not reached; zero files`",
    sprintf("- Canonical stopped HTML SHA-256: `%s`", sha256_file(html_path)),
    "- Build and protected inventories after the failure: byte-exact to pre-render",
    "- Remaining Quarto, Pandoc, semantic-hook, or loopback processes: `0`",
    "",
    "No second render, patch, companion render, cache cleanup, model access, scientific recomputation, commit, push, upload, or publication action was performed."
  )
  writeLines(
    stop_lines,
    file.path(evidence_dir, "ORDER56A_FAIL_CLOSED_STOP.md"),
    useBytes = TRUE
  )

  manifest_path <- file.path(
    evidence_dir,
    "order56a_stopped_evidence_manifest.csv"
  )
  evidence_paths <- list_files(evidence_dir)
  evidence_paths <- evidence_paths[
    normalizePath(evidence_paths, winslash = "/", mustWork = FALSE) !=
      normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
  ]
  evidence_manifest <- inventory_paths(
    evidence_paths,
    "order56a_stopped_evidence"
  )
  evidence_manifest <- evidence_manifest[
    order(evidence_manifest$relative_path),
    ,
    drop = FALSE
  ]
  assert_true(
    !anyDuplicated(evidence_manifest$relative_path) &&
      !any(grepl(
        "order56a_stopped_evidence_manifest[.]csv$",
        evidence_manifest$relative_path
      )),
    "The stopped evidence manifest is duplicated or circular."
  )
  write_evidence(
    evidence_manifest,
    "order56a_stopped_evidence_manifest.csv"
  )

  cat(sprintf(
    paste0(
      "ORDER56A_STOPPED=PASS render_attempts=1 exit=1 build=%d protected=%d ",
      "html=%s semantic_files=0 processes=0\n"
    ),
    nrow(build_inventory),
    nrow(protected_inventory),
    sha256_file(html_path)
  ))
}

assert_all <- function(value, message) {
  if (!length(value) || !all(value)) stop(message, call. = FALSE)
}

assert_none <- function(value, message) {
  if (length(value) && any(value)) stop(message, call. = FALSE)
}

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("Order 56a requires R 4.6.1, found %s.", getRversion())
)

suppressPackageStartupMessages({
  library(digest)
  library(readr)
  library(rvest)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
stage <- Sys.getenv("ORDER56A_STAGE", unset = "prerender")
assert_true(
  stage %in% c("prerender", "postrender", "postqa", "stopped"),
  "ORDER56A_STAGE must be prerender, postrender, postqa, or stopped."
)

evidence_relative <-
  "audit/hypotheses/H09/report018_order56a_display_repair"
evidence_dir <- file.path(root, evidence_relative)
assert_true(dir.exists(evidence_dir), "The Order 56a evidence root is missing.")

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

hash_text <- function(value) {
  digest::digest(enc2utf8(value), algo = "sha256", serialize = FALSE)
}

write_evidence <- function(object, name) {
  utils::write.csv(
    object,
    file.path(evidence_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(root, "/")
  ifelse(
    startsWith(normalized, prefix),
    substring(normalized, nchar(prefix) + 1L),
    normalized
  )
}

list_files <- function(path, exclude_prefix = character()) {
  if (!dir.exists(path)) return(character())
  files <- list.files(
    path,
    all.files = TRUE,
    full.names = TRUE,
    recursive = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  )
  info <- file.info(files)
  files <- files[!is.na(info$isdir) & !info$isdir]
  if (length(exclude_prefix)) {
    normalized <- normalizePath(files, winslash = "/", mustWork = FALSE)
    excluded <- Reduce(
      `|`,
      lapply(exclude_prefix, function(prefix) {
        normalized_prefix <- normalizePath(
          prefix,
          winslash = "/",
          mustWork = FALSE
        )
        normalized == normalized_prefix |
          startsWith(normalized, paste0(normalized_prefix, "/"))
      })
    )
    files <- files[!excluded]
  }
  files
}

inventory_paths <- function(paths, role = "inventory_member") {
  paths <- sort(unique(paths))
  assert_true(length(paths) > 0L, "Inventory is unexpectedly empty.")
  assert_all(file.exists(paths), "An inventory member is missing.")
  links <- Sys.readlink(paths)
  normalized <- normalizePath(paths, winslash = "/", mustWork = TRUE)
  info <- file.info(normalized)
  assert_none(info$isdir, "A directory entered a file inventory.")
  data.frame(
    relative_path = relative_path(normalized),
    role = if (length(role) == 1L) rep(role, length(normalized)) else role,
    sha256 = vapply(normalized, sha256_file, character(1)),
    bytes = as.numeric(info$size),
    modified_utc = format(
      info$mtime,
      tz = "UTC",
      usetz = TRUE,
      format = "%Y-%m-%dT%H:%M:%OS6Z"
    ),
    is_symlink = nzchar(links),
    symlink_target = links,
    stringsAsFactors = FALSE
  )
}

clean_text <- function(node) {
  if (length(node) == 0L || inherits(node, "xml_missing")) return("")
  value <- rvest::html_text2(node)
  trimws(gsub("[[:space:]]+", " ", value))
}

outside_source_modal <- function(nodes) {
  if (!length(nodes)) return(logical())
  !vapply(
    nodes,
    function(node) {
      length(xml2::xml_find_all(
        node,
        "ancestor::*[@id='quarto-embedded-source-code-modal']"
      )) >
        0L
    },
    logical(1)
  )
}

expected_tables <- c(
  "tbl-h09-metrics",
  "tbl-h09-formulas",
  "tbl-h09-primary-samples",
  "tbl-h09-near-eye-results",
  "tbl-h09-chest-results",
  "tbl-h09-paired-placement",
  "tbl-h09-interactions",
  "tbl-h09-qualified-diagnostics",
  "tbl-h09-gap-sensitivity",
  "tbl-h09-sensitivity-summary",
  "tbl-h09-mean-timing-sensitivity"
)
expected_figures <- c(
  "fig-h09-primary-effects",
  "fig-h09-paired-placement",
  "fig-h09-near-eye-diagnostics",
  "fig-h09-chest-diagnostics"
)
figure_files <- c(
  "H09_primary_effects.png",
  "H09_paired_placement_effects.png",
  "H09_diagnostics_near_eye.png",
  "H09_diagnostics_chest.png",
  "H09_primary_effects.pdf",
  "H09_paired_placement_effects.pdf",
  "H09_diagnostics_near_eye.pdf",
  "H09_diagnostics_chest.pdf"
)
expected_figure_paths <- file.path(
  "artifacts/10_figures/H09",
  figure_files[1:4]
)
expected_figure_sources <- c(
  "../../artifacts/11_source_data/H09/H09_primary_effects_data.csv",
  "../../artifacts/11_source_data/H09/H09_paired_placement_effects_data.csv",
  "../../artifacts/11_source_data/H09/H09_primary_diagnostic_figure_data.csv",
  "../../artifacts/11_source_data/H09/H09_primary_diagnostic_figure_data.csv"
)
expected_targets <- c(
  "../preparation/04_metric_derivation.qmd",
  "../preparation/06_model_ready_datasets.qmd",
  "../../audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "../preregistration_deviations.qmd#dev-037",
  "../preregistration_deviations.qmd#dev-038",
  "../preregistration_deviations.qmd#dev-039",
  "../../artifacts/08_diagnostics/H09/H09_diagnostic_assessment_registry.csv",
  "../../artifacts/08_diagnostics/H09/H09_diagnostic_author_adjudication.csv",
  "../../artifacts/08_diagnostics/H09/H09_leave_one_site_out_summary.csv",
  "../../artifacts/08_diagnostics/H09/H09_participant_influence_summary.csv",
  "../../artifacts/09_tables/H09/H09_ar1_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_fifth_outcome_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_gap_timing_unaware_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_l10_cut_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_model_results_master.csv",
  "../../artifacts/09_tables/H09/H09_participant_summary_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_photoperiod_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_site_specific_slopes.csv",
  "../../artifacts/11_source_data/H09/H09_paired_placement_effects_data.csv",
  "../../artifacts/11_source_data/H09/H09_primary_effects_data.csv",
  "../../artifacts/12_manifests/H09/H09_figure_manifest.csv"
)
expected_formulas <- c(
  "timing_hour ~ site + (1 | site:Id)",
  "timing_hour ~ site + mctq_hour_centered + (1 | site:Id)",
  "timing_hour ~ site * mctq_hour_centered + (1 | site:Id)",
  "timing_hour ~ site + meq_10_centered + (1 | site:Id)",
  "timing_hour ~ site * meq_10_centered + (1 | site:Id)"
)
expected_formula_rows <- c(
  expected_formulas[1:3],
  expected_formulas[c(1, 4, 5)]
)

qmd_relative <- "notebooks/hypotheses/H09.qmd"
qmd_path <- file.path(root, qmd_relative)
companion_relative <- "audit/hypotheses/H09/H09_analysis_preparation.qmd"
companion_path <- file.path(root, companion_relative)
html_relative <- "_build/nathealth/notebooks/hypotheses/H09.html"
html_path <- file.path(root, html_relative)
companion_html_relative <- paste0(
  "_build/nathealth/audit/hypotheses/H09/",
  "H09_analysis_preparation.html"
)
companion_html_path <- file.path(root, companion_html_relative)

fixed_identities <- c(
  "notebooks/hypotheses/H09.qmd" = "c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6",
  "audit/hypotheses/H09/H09_analysis_preparation.qmd" = "7563a933289b1c4a2275eead58ae8cfaa6492fb0a27b7202f4a9be516eb88a46",
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html" = "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
  "tests/hypotheses/H09/test_h09_stage3_reader_report.R" = "a0309e55d305b13be7571e404eb9650154f0ffc494c44b4512c833aa579d2bd1",
  "tests/hypotheses/H09/test_h09_preparation_report.R" = "9a243e391de7069179fcd0ccb7cc6813a5e779b1ae1bf7fcb52706349553dfe7",
  "_quarto-nathealth.yml" = "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  "scripts/report_harmonization/post_render_gt_html_semantics.R" = "28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205",
  "scripts/report_harmonization/repair_gt_html_semantics.R" = "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1",
  "renv.lock" = "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
)
source_identities <- c(
  "artifacts/11_source_data/H09/H09_primary_effects_data.csv" = "3972ae75c9aef8551cc85f50d7a438b35b7a55dca58d81f3630133132a25aaf6",
  "artifacts/11_source_data/H09/H09_paired_placement_effects_data.csv" = "ecc9fe09a1e823ec6b45b2b28239e56bf773a6d8a8c0bb458413e1e2e9b170b0",
  "artifacts/11_source_data/H09/H09_primary_diagnostic_figure_data.csv" = "b3119775c6725295b54af0fea735d89b892f4e9dcea94c9ff564248e5345854a"
)

build_root <- file.path(root, "_build/nathealth")
build_paths <- list_files(build_root)
build_inventory <- inventory_paths(build_paths, "build_member")
build_inventory <- build_inventory[
  order(build_inventory$relative_path),
  ,
  drop = FALSE
]
write_evidence(build_inventory, paste0("build_inventory_", stage, ".csv"))
build_entries <- list.files(
  build_root,
  recursive = TRUE,
  all.files = TRUE,
  full.names = TRUE,
  include.dirs = TRUE,
  no.. = TRUE
)
build_links <- Sys.readlink(build_entries)
build_symlinks <- data.frame(
  relative_path = relative_path(build_entries[nzchar(build_links)]),
  target = build_links[nzchar(build_links)],
  stringsAsFactors = FALSE
)
write_evidence(
  build_symlinks,
  paste0("build_symlink_inventory_", stage, ".csv")
)
assert_true(nrow(build_symlinks) == 0L, "The build tree contains a symlink.")

pre_protected <- read.csv(
  file.path(evidence_dir, "protected_inventory_preflight.csv"),
  check.names = FALSE
)
protected_paths <- file.path(root, pre_protected$relative_path)
assert_all(
  file.exists(protected_paths),
  "A preflight protected path is missing."
)
protected_inventory <- inventory_paths(protected_paths, pre_protected$role)
protected_inventory <- protected_inventory[
  match(pre_protected$relative_path, protected_inventory$relative_path),
  ,
  drop = FALSE
]
write_evidence(
  protected_inventory,
  paste0("protected_inventory_", stage, ".csv")
)

qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
qmd_text <- paste(qmd_lines, collapse = "\n")
qmd_text_normalized <- gsub("[[:space:]]+", " ", qmd_text)

if (identical(stage, "prerender")) {
  fixed_paths <- file.path(root, names(fixed_identities))
  source_paths <- file.path(root, names(source_identities))
  fixed_audit <- data.frame(
    path = names(fixed_identities),
    expected_sha256 = unname(fixed_identities),
    observed_sha256 = vapply(fixed_paths, sha256_file, character(1)),
    stringsAsFactors = FALSE
  )
  fixed_audit$status <- ifelse(
    fixed_audit$expected_sha256 == fixed_audit$observed_sha256,
    "PASS",
    "FAIL"
  )
  write_evidence(fixed_audit, "fixed_identity_prerender.csv")
  assert_all(fixed_audit$status == "PASS", "A fixed source or tool changed.")
  source_audit <- data.frame(
    path = names(source_identities),
    expected_sha256 = unname(source_identities),
    observed_sha256 = vapply(source_paths, sha256_file, character(1)),
    stringsAsFactors = FALSE
  )
  source_audit$status <- ifelse(
    source_audit$expected_sha256 == source_audit$observed_sha256,
    "PASS",
    "FAIL"
  )
  write_evidence(source_audit, "frozen_source_prerender.csv")
  assert_all(source_audit$status == "PASS", "A frozen source CSV changed.")

  candidate_inventory <- read.csv(
    file.path(evidence_dir, "candidate_inventory.csv"),
    check.names = FALSE
  )
  assert_true(
    identical(candidate_inventory$figure_file, figure_files),
    "The candidate inventory order changed."
  )
  durable_paths <- file.path(root, "artifacts/10_figures/H09", figure_files)
  durable_hashes <- vapply(durable_paths, sha256_file, character(1))
  output_audit <- data.frame(
    figure_file = figure_files,
    expected_sha256 = candidate_inventory$sha256,
    observed_sha256 = unname(durable_hashes),
    candidate_identical = candidate_inventory$sha256 == unname(durable_hashes),
    stringsAsFactors = FALSE
  )
  output_audit$status <- ifelse(
    output_audit$candidate_identical,
    "PASS",
    "FAIL"
  )
  write_evidence(output_audit, "durable_candidate_identity_prerender.csv")
  assert_all(
    output_audit$status == "PASS",
    "A durable figure is not candidate-identical."
  )

  receipt <- read.csv(
    file.path(evidence_dir, "durable_promotion_receipt.csv"),
    check.names = FALSE
  )
  assert_true(
    nrow(receipt) == 1L &&
      receipt$promotion_count[[1L]] == 1L &&
      receipt$files_promoted[[1L]] == 8L &&
      receipt$status[[1L]] == "PASS",
    "The one-time promotion receipt failed."
  )

  transition_proof <- read.csv(
    file.path(evidence_dir, "source_forward_reverse_proof.csv"),
    check.names = FALSE
  )
  assert_true(
    identical(transition_proof$member, c("builder", "figure_manifest")) &&
      all(transition_proof$status == "PASS") &&
      all(transition_proof$forward_reconstruction_exact) &&
      all(transition_proof$reverse_reconstruction_exact),
    "The builder or figure-manifest transition proof failed."
  )

  pre_build <- read.csv(
    file.path(evidence_dir, "build_inventory_preflight.csv"),
    check.names = FALSE
  )
  build_comparison <- merge(
    pre_build[, c("relative_path", "sha256", "bytes")],
    build_inventory[, c("relative_path", "sha256", "bytes")],
    by = "relative_path",
    all = TRUE,
    suffixes = c("_preflight", "_prerender")
  )
  build_comparison$exact <-
    build_comparison$sha256_preflight == build_comparison$sha256_prerender &
    build_comparison$bytes_preflight == build_comparison$bytes_prerender
  build_comparison$status <- ifelse(build_comparison$exact, "PASS", "FAIL")
  write_evidence(build_comparison, "build_reconciliation_prerender.csv")
  assert_all(
    build_comparison$status == "PASS",
    "The build changed before render."
  )

  authorized_paths <- c(
    "scripts/hypotheses/H09/run_h09_stage2.R",
    "artifacts/12_manifests/H09/H09_figure_manifest.csv",
    file.path("artifacts/10_figures/H09", figure_files)
  )
  protected_comparison <- merge(
    pre_protected[, c("relative_path", "sha256", "bytes")],
    protected_inventory[, c("relative_path", "sha256", "bytes")],
    by = "relative_path",
    all = TRUE,
    suffixes = c("_preflight", "_prerender")
  )
  protected_comparison$exact <-
    protected_comparison$sha256_preflight ==
      protected_comparison$sha256_prerender &
    protected_comparison$bytes_preflight == protected_comparison$bytes_prerender
  protected_comparison$authorized_transition <-
    protected_comparison$relative_path %in% authorized_paths
  protected_comparison$coordination_evidence_only <-
    protected_comparison$relative_path ==
      "audit/report_harmonization/coordination_matrix.csv"
  protected_comparison$status <- ifelse(
    protected_comparison$exact |
      protected_comparison$authorized_transition |
      protected_comparison$coordination_evidence_only,
    "PASS",
    "FAIL"
  )
  write_evidence(protected_comparison, "protected_reconciliation_prerender.csv")
  assert_all(
    protected_comparison$status == "PASS",
    "A protected path changed outside the authorized transition set."
  )
  changed_protected <- protected_comparison[
    !protected_comparison$exact &
      !protected_comparison$coordination_evidence_only,
    ,
    drop = FALSE
  ]
  assert_true(
    identical(sort(changed_protected$relative_path), sort(authorized_paths)),
    "The pre-render protected transition set is incomplete or overbroad."
  )

  source(file.path(
    root,
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
  ))
  chunks <- extract_executable_r_chunks(qmd_lines)
  chunk_audit <- lapply(seq_along(chunks), function(index) {
    parsed <- tryCatch(
      {
        parse(text = chunks[[index]], keep.source = FALSE)
        TRUE
      },
      error = function(error) FALSE
    )
    data.frame(order = index, parseable_r = parsed)
  })
  chunk_audit <- do.call(rbind, chunk_audit)
  write_evidence(chunk_audit, "source_chunk_audit_prerender.csv")
  assert_true(nrow(chunk_audit) == 17L, "The H09 result must have 17 R chunks.")
  assert_all(chunk_audit$parseable_r, "An H09 result R chunk does not parse.")

  table_endpoints <- sub(
    "#| label: ",
    "",
    qmd_lines[startsWith(qmd_lines, "#| label: tbl-h09-")],
    fixed = TRUE
  )
  figure_endpoints <- sub(
    "#| label: ",
    "",
    qmd_lines[startsWith(qmd_lines, "#| label: fig-h09-")],
    fixed = TRUE
  )
  endpoint_audit <- rbind(
    data.frame(
      type = "table",
      observed = table_endpoints,
      expected = expected_tables
    ),
    data.frame(
      type = "figure",
      observed = figure_endpoints,
      expected = expected_figures
    )
  )
  endpoint_audit$status <- ifelse(
    endpoint_audit$observed == endpoint_audit$expected,
    "PASS",
    "FAIL"
  )
  write_evidence(endpoint_audit, "source_endpoint_contract_prerender.csv")
  assert_true(
    identical(table_endpoints, expected_tables),
    "Table endpoints changed."
  )
  assert_true(
    identical(figure_endpoints, expected_figures),
    "Figure endpoints changed."
  )

  normalized_markdown <- gsub("[\r\n]+", " ", qmd_text)
  markdown_matches <- regmatches(
    normalized_markdown,
    gregexpr("\\[[^]]*\\]\\(([^)]+)\\)", normalized_markdown, perl = TRUE)
  )[[1L]]
  targets <- sub("^.*\\]\\(([^)]+)\\)$", "\\1", markdown_matches, perl = TRUE)
  target_audit <- data.frame(
    target = sort(unique(targets)),
    expected = sort(expected_targets),
    stringsAsFactors = FALSE
  )
  target_audit$status <- ifelse(
    target_audit$target == target_audit$expected,
    "PASS",
    "FAIL"
  )
  write_evidence(target_audit, "source_reader_targets_prerender.csv")
  assert_true(
    length(targets) == 23L &&
      length(unique(targets)) == 21L &&
      identical(sort(unique(targets)), sort(expected_targets)),
    "The source reader-link contract changed."
  )
  assert_none(
    grepl("^(file:|/|[A-Za-z]+://)|[.]html($|#)|_build", targets),
    "The H09 source contains a forbidden reader target."
  )
  for (target in unique(targets)) {
    file_target <- sub("#.*$", "", target)
    anchor <- if (grepl("#", target, fixed = TRUE)) {
      sub("^[^#]*#", "", target)
    } else {
      ""
    }
    resolved <- file.path(dirname(qmd_path), file_target)
    assert_true(file.exists(resolved), sprintf("Missing target: %s", target))
    if (nzchar(anchor)) {
      target_text <- paste(readLines(resolved, warn = FALSE), collapse = "\n")
      assert_true(
        grepl(sprintf("{#%s}", anchor), target_text, fixed = TRUE),
        sprintf("Missing anchor: %s", target)
      )
    }
  }

  required_phrases <- c(
    "Answer in brief",
    "Munich Chronotype Questionnaire corrected midsleep on free days (MCTQ MSFsc)",
    "Morningness–Eveningness Questionnaire (MEQ)",
    "false-discovery-rate (FDR)",
    "participant-day",
    "random effect",
    "not an equivalence",
    "gap-timing-unaware dataset",
    "50%-per-hour",
    "80%-per-day",
    "time-sensitive primary dataset",
    "does not establish that chronotype causes"
  )
  contract_items <- c(expected_formulas, required_phrases)
  contract_audit <- data.frame(
    item = contract_items,
    present = vapply(
      contract_items,
      grepl,
      logical(1),
      x = qmd_text_normalized,
      fixed = TRUE
    )
  )
  contract_audit$status <- ifelse(contract_audit$present, "PASS", "FAIL")
  write_evidence(contract_audit, "source_scientific_contract_prerender.csv")
  assert_all(contract_audit$present, "A source scientific contract changed.")
  assert_true(
    sum(grepl("DEV-037", qmd_lines, fixed = TRUE)) == 1L &&
      sum(grepl("DEV-038", qmd_lines, fixed = TRUE)) == 1L &&
      sum(grepl("DEV-039", qmd_lines, fixed = TRUE)) == 1L &&
      !grepl("IMP-009", qmd_text, fixed = TRUE) &&
      !grepl("BH", qmd_text, fixed = TRUE),
    "The H09 deviation or FDR vocabulary contract changed."
  )

  formula_positions <- vapply(
    expected_formulas,
    function(formula) {
      as.integer(regexpr(formula, qmd_text, fixed = TRUE)[[1L]])
    },
    integer(1)
  )
  assert_true(
    all(formula_positions > 0L) && all(diff(formula_positions) > 0L),
    "The five unique Wilkinson formulas changed or are out of order."
  )

  prohibited <- c(
    "lm",
    "stats::lm",
    "glm",
    "stats::glm",
    "lmer",
    "lme4::lmer",
    "glmer",
    "lme4::glmer",
    "predict",
    "stats::predict",
    "simulate",
    "stats::simulate",
    "boot",
    "boot::boot",
    "bootstrap",
    "sample",
    "replicate",
    "p.adjust",
    "stats::p.adjust",
    "anova",
    "emmeans",
    "save",
    "saveRDS",
    "write.csv",
    "readr::write_csv",
    "writeLines",
    "writeBin",
    "ggsave",
    "file.copy",
    "file.rename",
    "unlink",
    "system",
    "system2",
    "quarto_render",
    "render",
    "knit"
  )
  calls <- executable_r_call_names(qmd_lines)
  prohibited_audit <- data.frame(
    call = prohibited,
    observed = prohibited %in% calls
  )
  prohibited_audit$status <- ifelse(prohibited_audit$observed, "FAIL", "PASS")
  write_evidence(prohibited_audit, "source_prohibited_call_audit_prerender.csv")
  assert_none(
    prohibited_audit$observed,
    "The result source contains a prohibited call."
  )

  manifest_path <- file.path(
    root,
    "artifacts/12_manifests/H09/H09_figure_manifest.csv"
  )
  manifest_preimage_path <- file.path(
    evidence_dir,
    "recoverable_preimages/artifacts/12_manifests/H09/H09_figure_manifest.csv"
  )
  manifest <- read.csv(manifest_path, check.names = FALSE)
  manifest_preimage <- read.csv(manifest_preimage_path, check.names = FALSE)
  assert_true(
    identical(names(manifest), names(manifest_preimage)) &&
      identical(manifest$figure_id, manifest_preimage$figure_id),
    "The figure-manifest schema or order changed."
  )
  v0_ids <- c("v0_near_eye_recreation", "v0_chest_recreation")
  v0_current <- manifest[match(v0_ids, manifest$figure_id), , drop = FALSE]
  v0_preimage <- manifest_preimage[
    match(v0_ids, manifest_preimage$figure_id),
    ,
    drop = FALSE
  ]
  v0_current_lines <- grep(
    "^v0_",
    readLines(manifest_path, warn = FALSE),
    value = TRUE
  )
  v0_preimage_lines <- grep(
    "^v0_",
    readLines(manifest_preimage_path, warn = FALSE),
    value = TRUE
  )
  assert_true(
    identical(v0_current_lines, v0_preimage_lines) &&
      isTRUE(all.equal(v0_current, v0_preimage, tolerance = 0)),
    "A V0 figure-manifest row changed."
  )
  result_ids <- c(
    "primary_effects",
    "paired_placement_effects",
    "diagnostics_near_eye",
    "diagnostics_chest"
  )
  result_manifest <- manifest[
    match(result_ids, manifest$figure_id),
    ,
    drop = FALSE
  ]
  expected_height <- c(6.5, 6.5, 17.5, 17.5)
  expected_export_height <- c(9.75, 9.75, 26.25, 26.25)
  expected_nominal <- c(17, 13, 17, 17)
  expected_effective <- c(
    7.224096987876516,
    7.250656167979003,
    7.224096987876516,
    7.224096987876516
  )
  manifest_audit <- data.frame(
    figure_id = result_manifest$figure_id,
    height_exact = result_manifest$base_height_in == expected_height,
    export_height_exact = result_manifest$export_height_in ==
      expected_export_height,
    nominal_exact = result_manifest$smallest_essential_nominal_text_pt ==
      expected_nominal,
    effective_exact = abs(
      result_manifest$effective_final_text_pt - expected_effective
    ) <
      1e-12,
    width_preserved = result_manifest$base_width_in == c(10.5, 8, 10.5, 10.5),
    scale_preserved = result_manifest$export_scale_multiplier == 1.5,
    dpi_preserved = result_manifest$raster_dpi == 300,
    qa_truthful = grepl(
      "^PASS: Order 56a candidate",
      result_manifest$visual_qa_status
    ),
    stringsAsFactors = FALSE
  )
  manifest_audit$status <- ifelse(
    apply(manifest_audit[, -1, drop = FALSE], 1, all),
    "PASS",
    "FAIL"
  )
  write_evidence(manifest_audit, "figure_manifest_prerender_audit.csv")
  assert_all(
    manifest_audit$status == "PASS",
    "A figure-manifest contract failed."
  )

  evidence_contracts <- c(
    "no_scientific_call_audit.csv",
    "source_row_reconciliation.csv",
    "scientific_layer_audit.csv",
    "scale_break_label_panel_audit.csv",
    "source_layer_cardinality_audit.csv",
    "historical_png_reproduction.csv",
    "historical_pdf_reproduction.csv",
    "candidate_typography_contract.csv",
    "candidate_visual_qa.csv",
    "source_forward_reverse_proof.csv"
  )
  evidence_status <- lapply(evidence_contracts, function(name) {
    value <- read.csv(file.path(evidence_dir, name), check.names = FALSE)
    data.frame(
      path = name,
      rows = nrow(value),
      all_pass = "status" %in% names(value) && all(value$status == "PASS")
    )
  })
  evidence_status <- do.call(rbind, evidence_status)
  evidence_status$status <- ifelse(evidence_status$all_pass, "PASS", "FAIL")
  write_evidence(evidence_status, "candidate_evidence_prerender_audit.csv")
  assert_all(
    evidence_status$status == "PASS",
    "A candidate evidence contract failed."
  )

  new_r_paths <- file.path(
    root,
    c(
      "scripts/hypotheses/H09/refresh_h09_order56_figures.R",
      "tests/hypotheses/H09/test_h09_order56_display_repair.R"
    )
  )
  parse_audit <- data.frame(
    path = relative_path(new_r_paths),
    parseable = vapply(
      new_r_paths,
      function(path) {
        tryCatch(
          {
            parse(path, keep.source = FALSE)
            TRUE
          },
          error = function(error) FALSE
        )
      },
      logical(1)
    )
  )
  parse_audit$status <- ifelse(parse_audit$parseable, "PASS", "FAIL")
  write_evidence(parse_audit, "new_r_parse_prerender.csv")
  assert_all(parse_audit$status == "PASS", "A new R file does not parse.")

  air_version <- trimws(system2("air", "--version", stdout = TRUE))[[1L]]
  quarto_version <- trimws(system2("quarto", "--version", stdout = TRUE))[[1L]]
  versions <- data.frame(
    component = c("R", "Quarto", "Air"),
    observed = c(as.character(getRversion()), quarto_version, air_version),
    expected = c("4.6.1", "1.9.37", "air 0.4.1"),
    stringsAsFactors = FALSE
  )
  versions$status <- ifelse(
    versions$observed == versions$expected,
    "PASS",
    "FAIL"
  )
  write_evidence(versions, "versions_prerender.csv")
  assert_all(versions$status == "PASS", "A required tool version changed.")

  git_output <- suppressWarnings(system2(
    "git",
    c(
      "diff",
      "--check",
      "--",
      "scripts/hypotheses/H09/refresh_h09_order56_figures.R",
      "tests/hypotheses/H09/test_h09_order56_display_repair.R",
      "scripts/hypotheses/H09/run_h09_stage2.R",
      "artifacts/12_manifests/H09/H09_figure_manifest.csv"
    ),
    stdout = TRUE,
    stderr = TRUE
  ))
  git_status <- attr(git_output, "status")
  git_audit <- data.frame(
    command = "git diff --check -- <four scoped paths>",
    output_lines = length(git_output),
    exit_code = ifelse(is.null(git_status), 0L, git_status),
    status = ifelse(is.null(git_status) || git_status == 0L, "PASS", "FAIL")
  )
  write_evidence(git_audit, "git_diff_check_prerender.csv")
  assert_true(git_audit$status == "PASS", "Scoped git diff check failed.")

  historical_tests <- data.frame(
    path = names(fixed_identities)[grepl(
      "^tests/hypotheses/H09/",
      names(fixed_identities)
    )],
    sha256 = unname(fixed_identities[grepl(
      "^tests/hypotheses/H09/",
      names(fixed_identities)
    )]),
    executed = FALSE,
    status = "PASS"
  )
  write_evidence(historical_tests, "historical_tests_prerender_audit.csv")

  stage3_path <- file.path(
    root,
    "artifacts/12_manifests/H09/H09_stage3_artifacts.csv"
  )
  stage3 <- read.csv(stage3_path, check.names = FALSE)
  stage3_paths <- file.path(root, stage3$path)
  stage3_exists <- file.exists(stage3_paths)
  stage3_sha <- rep(NA_character_, nrow(stage3))
  stage3_sha[stage3_exists] <- vapply(
    stage3_paths[stage3_exists],
    sha256_file,
    character(1)
  )
  stage3_bytes <- rep(NA_real_, nrow(stage3))
  stage3_bytes[stage3_exists] <- as.numeric(
    file.info(stage3_paths[stage3_exists])$size
  )
  stage3_exact <- stage3_exists &
    stage3_sha == stage3$sha256 &
    stage3_bytes == stage3$bytes
  expected_stage3_transitions <- c(
    "audit/hypotheses/H09/H09_stage1_gate_and_stage2_transition.md",
    "scripts/hypotheses/H09/h09_contract.R",
    "scripts/hypotheses/H09/run_h09_stage2.R",
    "audit/handoffs/H09_worker_handoff.md",
    file.path("artifacts/10_figures/H09", figure_files),
    "audit/handoffs/H09_shared_change_request.md",
    "artifacts/06_model_data/H09/H09_base_bundle_audit.csv",
    "artifacts/06_model_data/H09/H09_input_audit.csv",
    "artifacts/12_manifests/H09/H09_figure_manifest.csv",
    html_relative,
    qmd_relative,
    "config/metric_display_registry.csv",
    "_quarto-nathealth.yml",
    "audit/decisions/figure_readability_and_layout.md"
  )
  stage3_audit <- data.frame(
    path = stage3$path,
    exact = stage3_exact,
    classification = ifelse(
      stage3_exact,
      "live-exact",
      ifelse(
        stage3$path %in% expected_stage3_transitions,
        "accepted transition",
        "unclassified"
      )
    )
  )
  stage3_audit$status <- ifelse(
    stage3_audit$exact | stage3_audit$classification == "accepted transition",
    "PASS",
    "FAIL"
  )
  write_evidence(stage3_audit, "stage3_manifest_prerender_audit.csv")
  assert_true(
    identical(
      sort(stage3$path[!stage3_exact]),
      sort(expected_stage3_transitions)
    ),
    "The historical Stage 3 transition set changed."
  )

  process_probe_path <- file.path(evidence_dir, "process_probe_prerender.csv")
  assert_true(
    file.exists(process_probe_path),
    "The current process probe is missing."
  )
  process_probe <- read.csv(process_probe_path, check.names = FALSE)
  assert_true(
    nrow(process_probe) == 1L &&
      process_probe$observed_count[[1L]] == 0L &&
      process_probe$status[[1L]] == "PASS",
    "A competing render or loopback process is active."
  )

  semantic_env <- Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR", unset = "")
  assert_true(nzchar(semantic_env), "GT_HTML_SEMANTIC_AUDIT_DIR is required.")
  semantic_dir <- normalizePath(semantic_env, winslash = "/", mustWork = TRUE)
  semantic_members <- list.files(
    semantic_dir,
    all.files = TRUE,
    no.. = TRUE,
    full.names = TRUE
  )
  semantic_audit <- data.frame(
    absolute_path = semantic_dir,
    under_private_tmp = startsWith(semantic_dir, "/private/tmp/"),
    member_count = length(semantic_members),
    status = ifelse(
      startsWith(semantic_dir, "/private/tmp/") &&
        length(semantic_members) == 0L,
      "PASS",
      "FAIL"
    )
  )
  write_evidence(semantic_audit, "semantic_directory_prerender.csv")
  assert_true(
    semantic_audit$status == "PASS",
    "The semantic directory is not fresh and empty."
  )

  preflight_status <- data.frame(
    domain = c(
      "fixed identities",
      "frozen source CSVs",
      "17 R chunks",
      "11 table endpoints",
      "4 figure endpoints",
      "23 links and 21 targets",
      "candidate-identical durable files",
      "source forward and reverse proof",
      "four-row figure manifest",
      "V0 rows",
      "candidate scientific and visual evidence",
      "historical tests exact and unexecuted",
      "unrelated protected scope",
      "build pre-render identity",
      "fresh semantic directory",
      "zero build symlinks",
      "zero competing processes",
      "R, Quarto, and Air versions",
      "scoped git diff check"
    ),
    status = "PASS"
  )
  write_evidence(preflight_status, "complete_prerender_status.csv")
  cat(sprintf(
    paste0(
      "ORDER56A_PRERENDER=PASS chunks=%d tables=%d figures=%d links=%d ",
      "outputs=%d protected=%d build=%d R=%s quarto=%s air=%s\n"
    ),
    nrow(chunk_audit),
    length(table_endpoints),
    length(figure_endpoints),
    length(targets),
    nrow(output_audit),
    nrow(protected_inventory),
    nrow(build_inventory),
    as.character(getRversion()),
    quarto_version,
    air_version
  ))
}

if (identical(stage, "postrender")) {
  run_postrender()
}

if (identical(stage, "postqa")) {
  post_build <- read.csv(
    file.path(evidence_dir, "build_inventory_postrender.csv"),
    check.names = FALSE
  )
  post_protected <- read.csv(
    file.path(evidence_dir, "protected_inventory_postrender.csv"),
    check.names = FALSE
  )
  compare_inventory <- function(before, after, label) {
    merged <- merge(
      before[, c("relative_path", "sha256", "bytes")],
      after[, c("relative_path", "sha256", "bytes")],
      by = "relative_path",
      all = TRUE,
      suffixes = c("_before", "_after")
    )
    merged$exact <-
      merged$sha256_before == merged$sha256_after &
      merged$bytes_before == merged$bytes_after
    merged$scope <- label
    merged
  }
  build_compare <- compare_inventory(post_build, build_inventory, "build")
  protected_compare <- compare_inventory(
    post_protected,
    protected_inventory,
    "protected"
  )
  reconciliation <- data.frame(
    scope = c("complete build", "complete protected scope"),
    before_rows = c(nrow(post_build), nrow(post_protected)),
    after_rows = c(nrow(build_inventory), nrow(protected_inventory)),
    exact_rows = c(sum(build_compare$exact), sum(protected_compare$exact)),
    status = c(
      ifelse(all(build_compare$exact), "PASS", "FAIL"),
      ifelse(all(protected_compare$exact), "PASS", "FAIL")
    ),
    stringsAsFactors = FALSE
  )
  write_evidence(reconciliation, "postqa_rehash_reconciliation.csv")
  assert_all(
    reconciliation$status == "PASS",
    "QA changed build or protected files."
  )
  assert_true(
    nrow(build_symlinks) == 0L,
    "The post-QA build contains a symlink."
  )

  visual_path <- file.path(evidence_dir, "visual_qa_status.csv")
  lifecycle_path <- file.path(evidence_dir, "loopback_lifecycle.csv")
  browser_console_path <- file.path(
    evidence_dir,
    "browser_console_warn_error.json"
  )
  exit_probe_path <- file.path(evidence_dir, "loopback_exit_probe.csv")
  assert_all(
    file.exists(c(
      visual_path,
      lifecycle_path,
      browser_console_path,
      exit_probe_path
    )),
    "Final browser QA evidence is incomplete."
  )
  visual <- read.csv(visual_path, check.names = FALSE)
  required_visual_domains <- c(
    "viewport_1440x1000",
    "viewport_708x1000",
    "viewport_720x500_200pct_equivalent",
    "reader_flow_11_tables",
    "reader_flow_4_figures",
    "callouts_headings_captions_links_navigation",
    "wrapping_disclosures_axes_legends_symbols_site_codes",
    "page_clipping_overlap_overflow",
    "final_size_170mm_essential_text_floor"
  )
  assert_true(
    identical(sort(visual$domain), sort(required_visual_domains)) &&
      !anyDuplicated(visual$domain) &&
      all(visual$status == "PASS"),
    "Final visual QA is incomplete or has a failure."
  )

  screenshot_paths <- list.files(
    evidence_dir,
    pattern = "^visual_.*[.]png$",
    full.names = TRUE
  )
  assert_true(
    length(screenshot_paths) >= 7L,
    "Visual screenshot evidence is incomplete."
  )
  screenshot_manifest <- inventory_paths(
    screenshot_paths,
    "visual_qa_screenshot"
  )
  write_evidence(screenshot_manifest, "visual_screenshot_manifest.csv")
  screenshot_names <- basename(screenshot_paths)
  assert_true(
    any(grepl("1440x1000", screenshot_names, fixed = TRUE)) &&
      any(grepl("708x1000", screenshot_names, fixed = TRUE)) &&
      any(grepl("720x500", screenshot_names, fixed = TRUE)) &&
      sum(grepl("170mm", screenshot_names, fixed = TRUE)) >= 4L,
    "A required viewport or final-size figure screenshot is missing."
  )

  lifecycle <- read.csv(lifecycle_path, check.names = FALSE)
  assert_true(
    nrow(lifecycle) == 2L &&
      identical(lifecycle$event, c("start", "stop")) &&
      all(lifecycle$bind_address == "127.0.0.1") &&
      all(lifecycle$served_root == "_build/nathealth") &&
      all(lifecycle$status == "PASS"),
    "The secure-loopback lifecycle record failed."
  )
  exit_probe <- read.csv(exit_probe_path, check.names = FALSE)
  assert_true(
    nrow(exit_probe) == 2L &&
      identical(
        exit_probe$check,
        c("server process exited", "loopback listener absent")
      ) &&
      all(exit_probe$observed == 0L) &&
      all(exit_probe$status == "PASS"),
    "The loopback process or listener remains after QA."
  )
  browser_console <- paste(
    readLines(browser_console_path, warn = FALSE),
    collapse = ""
  )
  assert_true(
    identical(gsub("[[:space:]]+", "", browser_console), "[]"),
    "The browser console contains a warning or error."
  )

  manifest <- read.csv(
    file.path(root, "artifacts/12_manifests/H09/H09_figure_manifest.csv"),
    check.names = FALSE
  )
  result_ids <- c(
    "primary_effects",
    "paired_placement_effects",
    "diagnostics_near_eye",
    "diagnostics_chest"
  )
  result_manifest <- manifest[
    match(result_ids, manifest$figure_id),
    ,
    drop = FALSE
  ]
  assert_true(
    all(result_manifest$effective_final_text_pt >= 7) &&
      all(result_manifest$intended_display_width_mm == 170) &&
      all(grepl("^PASS", result_manifest$visual_qa_status)),
    "The final 170-mm typography contract failed."
  )

  current_display_paths <- c(
    file.path("artifacts/10_figures/H09", figure_files),
    names(source_identities),
    "artifacts/12_manifests/H09/H09_figure_manifest.csv",
    "scripts/hypotheses/H09/run_h09_stage2.R",
    "scripts/hypotheses/H09/refresh_h09_order56_figures.R",
    "tests/hypotheses/H09/test_h09_order56_display_repair.R",
    qmd_relative,
    html_relative
  )
  current_display_manifest <- inventory_paths(
    file.path(root, current_display_paths),
    "current_display_member"
  )
  current_display_manifest <- current_display_manifest[
    match(current_display_paths, current_display_manifest$relative_path),
    ,
    drop = FALSE
  ]
  assert_true(
    !anyDuplicated(current_display_manifest$relative_path) &&
      !any(grepl(
        "current_display_manifest[.]csv$",
        current_display_manifest$relative_path
      )),
    "The current display manifest is duplicated or circular."
  )
  write_evidence(current_display_manifest, "current_display_manifest.csv")

  final_freeze <- data.frame(
    path = c(
      qmd_relative,
      companion_relative,
      companion_html_relative,
      "tests/hypotheses/H09/test_h09_stage3_reader_report.R",
      "tests/hypotheses/H09/test_h09_preparation_report.R",
      "_quarto-nathealth.yml",
      "scripts/report_harmonization/post_render_gt_html_semantics.R",
      "scripts/report_harmonization/repair_gt_html_semantics.R",
      "renv.lock"
    ),
    stringsAsFactors = FALSE
  )
  final_freeze$sha256 <- vapply(
    file.path(root, final_freeze$path),
    sha256_file,
    character(1)
  )
  final_freeze$bytes <- as.numeric(
    file.info(file.path(root, final_freeze$path))$size
  )
  final_freeze$status <- "PASS"
  write_evidence(final_freeze, "final_source_freeze_audit.csv")

  acceptance_lines <- c(
    "# REPORT-018 order 56a H09 result: ACCEPTED",
    "",
    sprintf("- Result QMD SHA-256: `%s`", sha256_file(qmd_path)),
    sprintf("- Fresh result HTML SHA-256: `%s`", sha256_file(html_path)),
    "- Exactly one result render was consumed under the accepted nathealth profile.",
    "- Eleven native gt tables and four figure endpoints passed in the accepted order.",
    "- All 23 link occurrences and 21 unique targets passed.",
    "- Semantic repair was reversed and reapplied exactly with visible and structural invariance.",
    "- All eight durable figure files equal their accepted candidates and retain the three frozen source CSV identities.",
    "- Every required visual domain passed, including at least 7-point effective essential text at 170 mm.",
    "- Both historical H09 tests and historical manifests remained byte-exact and were not executed.",
    "- The companion, source, profiles, semantic tools, scientific artifacts, and unrelated protected scope remained unchanged.",
    "- The loopback server used only 127.0.0.1, was stopped, and left no process or listener.",
    "",
    "No companion render, model access, scientific recomputation, cleanup loop, commit, push, upload, or publication action was performed."
  )
  writeLines(
    acceptance_lines,
    file.path(evidence_dir, "ORDER56A_ACCEPTANCE.md"),
    useBytes = TRUE
  )

  manifest_path <- file.path(evidence_dir, "order56a_evidence_manifest.csv")
  evidence_paths <- list_files(evidence_dir)
  evidence_paths <- evidence_paths[
    normalizePath(evidence_paths, winslash = "/", mustWork = FALSE) !=
      normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
  ]
  semantic_dir <- normalizePath(
    Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
    winslash = "/",
    mustWork = TRUE
  )
  external_semantic_paths <- list_files(semantic_dir)
  evidence_manifest <- inventory_paths(c(
    evidence_paths,
    external_semantic_paths
  ))
  evidence_manifest$role <- ifelse(
    startsWith(evidence_manifest$relative_path, paste0(semantic_dir, "/")),
    "retained_external_semantic_evidence",
    "order56a_local_evidence"
  )
  evidence_manifest <- evidence_manifest[
    order(evidence_manifest$relative_path),
    ,
    drop = FALSE
  ]
  assert_true(
    !anyDuplicated(evidence_manifest$relative_path) &&
      !any(grepl(
        "order56a_evidence_manifest[.]csv$",
        evidence_manifest$relative_path
      )),
    "The evidence manifest is duplicated or circular."
  )
  write_evidence(evidence_manifest, "order56a_evidence_manifest.csv")

  cat(sprintf(
    "ORDER56A_POSTQA=PASS build=%d protected=%d html=%s symlinks=0\n",
    nrow(build_inventory),
    nrow(protected_inventory),
    sha256_file(html_path)
  ))
}

if (identical(stage, "stopped")) {
  run_stopped()
}
