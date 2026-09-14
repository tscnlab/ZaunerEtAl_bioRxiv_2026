#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("This audit requires R 4.6.1.", call. = FALSE)
}

required_packages <- c("digest", "xml2", "png")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1L), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    sprintf("Missing package(s): %s", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
brown_root <- Sys.getenv(
  "BROWN_WORKTREE_ROOT",
  unset = "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
)
brown_root <- normalizePath(brown_root, winslash = "/", mustWork = TRUE)

sha256 <- function(path) {
  unname(digest::digest(path, algo = "sha256", file = TRUE))
}

read_bytes <- function(path) {
  size <- file.info(path)$size
  readChar(path, nchars = size, useBytes = TRUE)
}

text_sha256 <- function(text) {
  unname(digest::digest(
    charToRaw(enc2utf8(text)),
    algo = "sha256",
    serialize = FALSE
  ))
}

count_fixed <- function(text, pattern) {
  if (!nzchar(pattern)) {
    return(0L)
  }
  length(strsplit(text, pattern, fixed = TRUE)[[1L]]) - 1L
}

replace_exact <- function(text, old, new, expected_count = 1L) {
  observed <- count_fixed(text, old)
  if (!identical(observed, as.integer(expected_count))) {
    stop(
      sprintf(
        "Expected %d occurrence(s), found %d for: %s",
        expected_count,
        observed,
        substr(old, 1L, 120L)
      ),
      call. = FALSE
    )
  }
  gsub(old, new, text, fixed = TRUE)
}

extract_regex <- function(text, pattern) {
  hit <- gregexpr(pattern, text, perl = TRUE)[[1L]]
  if (identical(hit[[1L]], -1L)) {
    return(character())
  }
  regmatches(text, list(hit))[[1L]]
}

extract_links <- function(text) {
  raw <- extract_regex(text, "\\[[^]\\n]*\\]\\([^)]*\\)")
  sub("^.*\\(([^)]*)\\)$", "\\1", raw, perl = TRUE)
}

extract_inline_r <- function(text) {
  extract_regex(text, "`r [^`]+`")
}

extract_labels <- function(text) {
  sub(
    "^#\\| label:[[:space:]]*",
    "",
    extract_regex(text, "(?m)^#\\| label:[[:space:]]*[^\\n]+$")
  )
}

extract_numeric_tokens <- function(text) {
  sort(extract_regex(
    text,
    "(?<![[:alpha:]_])[-+]?[0-9]+(?:\\.[0-9]+)?(?:[eE][-+]?[0-9]+)?%?"
  ))
}

extract_r_chunks <- function(text) {
  starts <- gregexpr("(?m)^```\\{r[^\\n]*\\}[[:space:]]*$", text, perl = TRUE)[[
    1L
  ]]
  if (identical(starts[[1L]], -1L)) {
    return(character())
  }
  start_lengths <- attr(starts, "match.length")
  chunks <- character(length(starts))
  for (index in seq_along(starts)) {
    content_start <- starts[[index]] + start_lengths[[index]]
    remainder <- substring(text, content_start + 1L)
    close <- regexpr("(?m)^```[[:space:]]*$", remainder, perl = TRUE)[[1L]]
    if (identical(close, -1L)) {
      stop("An R chunk is missing its closing fence.", call. = FALSE)
    }
    chunks[[index]] <- substring(remainder, 1L, close - 1L)
  }
  chunks
}

parse_chunks <- function(text) {
  chunks <- extract_r_chunks(text)
  counts <- vapply(
    chunks,
    function(chunk) length(parse(text = chunk)),
    integer(1L)
  )
  list(chunks = length(chunks), expressions = sum(counts))
}

paths <- c(
  stage3_qmd = file.path(
    brown_root,
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd"
  ),
  stage3_html = file.path(
    brown_root,
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html"
  ),
  stage4_qmd = file.path(
    brown_root,
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd"
  ),
  stage4_html = file.path(
    brown_root,
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html"
  ),
  figure_builder = file.path(
    brown_root,
    paste0(
      "audit/analyses/brown_adherence/stage3_cross_state_association/",
      "integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/",
      "00_build_ba_m6_display.R"
    )
  ),
  figure_png = file.path(
    brown_root,
    paste0(
      "audit/analyses/brown_adherence/stage3_cross_state_association/",
      "integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/",
      "figures/main_site_free_work_forest_with_ba_m6.png"
    )
  ),
  figure_svg = file.path(
    brown_root,
    paste0(
      "audit/analyses/brown_adherence/stage3_cross_state_association/",
      "integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/",
      "figures/main_site_free_work_forest_with_ba_m6.svg"
    )
  ),
  figure_source = file.path(
    brown_root,
    paste0(
      "audit/analyses/brown_adherence/stage3_cross_state_association/",
      "integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/",
      "source_data/main_site_free_work_forest_with_ba_m6_source.csv"
    )
  ),
  multiplicity_source = file.path(
    brown_root,
    paste0(
      "audit/analyses/brown_adherence/stage4_cross_state_association/",
      "source_data/multiplicity_registry.csv"
    )
  ),
  source_acceptance = file.path(
    project_root,
    paste0(
      "audit/decisions/",
      "brown_adherence_stage3_stage4_language_harmonization_source_",
      "independent_acceptance.md"
    )
  ),
  stage3_acceptance = file.path(
    project_root,
    "audit/decisions/brown_adherence_stage3_order50_independent_acceptance.md"
  ),
  stage4_acceptance = file.path(
    project_root,
    paste0(
      "audit/decisions/",
      "brown_adherence_stage4_order51_environment_retry_independent_acceptance.md"
    )
  ),
  audit_inventory = file.path(
    project_root,
    "audit/report_harmonization/brown_ba_m_reader_label_audit.csv"
  ),
  display_candidate_audit = file.path(
    project_root,
    paste0(
      "audit/report_harmonization/",
      "brown_ba_m_reader_label_display_candidate_audit.csv"
    )
  ),
  change_matrix = file.path(
    project_root,
    "audit/report_harmonization/brown_ba_m_reader_label_change_matrix.csv"
  )
)

if (!all(file.exists(paths))) {
  stop("A required audit input is absent.", call. = FALSE)
}

expected_sha <- c(
  stage3_qmd = "2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43",
  stage3_html = "3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d",
  stage4_qmd = "628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475",
  stage4_html = "54e85fe7873a8b54772341ce95241e5dc93ec7ab14aef99f0b1b72773b0f5954",
  figure_builder = "b361b4492f5f2203ef117d8186163047140eab2fe6ea6d981dcd051500151404",
  figure_png = "c2c58e3c8119457975d57e94b062ddba41ca828ad4326b1e1e6ac19bb7f1151a",
  figure_svg = "126acff6b1794864fc5b5797915046f884cc0890d445adc2aa437058f6d90fe0",
  figure_source = "4c2d18282cd222930f91edac6606fd0a98ee313c975728a0cfe372ded565c1fc",
  multiplicity_source = "19925dc988c3dc650cea6a63b537138b1315df0d7ee44a6e76dff7ac967ee21f",
  source_acceptance = "eb7da424f42cc7e2e953c45a4e559fcff8c1375ec6e64f000520c4753580d6ca",
  stage3_acceptance = "cc5f751f7f86ce2ec1cd930f60bea19cca8e6bdfd2b33113c978694a6357a7be",
  stage4_acceptance = "9890452d0d970e37ed929823939898f2d13a8fbce910ad13912bc94568c54bd0"
)
expected_bytes <- c(
  stage3_qmd = 55426,
  stage3_html = 4825090,
  stage4_qmd = 24416,
  stage4_html = 4341698,
  figure_builder = 17802,
  figure_png = 350620,
  figure_svg = 32059,
  figure_source = 19620,
  multiplicity_source = 1276,
  source_acceptance = 4908,
  stage3_acceptance = 3779,
  stage4_acceptance = 3524
)

pinned_names <- names(expected_sha)
observed_sha <- vapply(paths[pinned_names], sha256, character(1L))
observed_bytes <- as.numeric(file.info(paths[pinned_names])$size)
if (!identical(unname(observed_sha), unname(expected_sha))) {
  stop("A pinned SHA-256 identity differs.", call. = FALSE)
}
if (!identical(unname(observed_bytes), unname(expected_bytes))) {
  stop("A pinned byte count differs.", call. = FALSE)
}

stage3 <- read_bytes(paths[["stage3_qmd"]])
stage4 <- read_bytes(paths[["stage4_qmd"]])
builder <- read_bytes(paths[["figure_builder"]])

label_pattern <- "BA-(?:CS-)?M[1-6]"
stage3_labels <- extract_regex(stage3, label_pattern)
stage4_labels <- extract_regex(stage4, label_pattern)
if (
  !identical(
    unname(sort(table(stage3_labels))),
    unname(sort(table(c(
      rep("BA-M4", 4L),
      rep("BA-M6", 4L)
    ))))
  )
) {
  stop("The Stage 3 source label inventory differs.", call. = FALSE)
}
expected_stage4_labels <- c(
  rep("BA-CS-M1", 1L),
  rep("BA-M1", 3L),
  rep("BA-M4", 3L),
  rep("BA-M5", 3L),
  rep("BA-M6", 8L)
)
if (
  !identical(
    unname(sort(table(stage4_labels))),
    unname(sort(table(expected_stage4_labels)))
  )
) {
  stop("The Stage 4 source label inventory differs.", call. = FALSE)
}

stage3_doc <- xml2::read_html(paths[["stage3_html"]])
stage4_doc <- xml2::read_html(paths[["stage4_html"]])
stage3_main_text <- xml2::xml_text(xml2::xml_find_all(
  stage3_doc,
  "//main//text()[contains(., 'BA-M') or contains(., 'BA-CS-M')]"
))
stage4_main_text <- xml2::xml_text(xml2::xml_find_all(
  stage4_doc,
  "//main//text()[contains(., 'BA-M') or contains(., 'BA-CS-M')]"
))
stage3_main_tokens <- unlist(lapply(
  stage3_main_text,
  extract_regex,
  pattern = label_pattern
))
stage4_main_tokens <- unlist(lapply(
  stage4_main_text,
  extract_regex,
  pattern = label_pattern
))
if (length(stage3_main_text) != 4L || length(stage3_main_tokens) != 5L) {
  stop(
    "The rendered Stage 3 normal-body label inventory differs.",
    call. = FALSE
  )
}
if (length(stage4_main_text) != 24L || length(stage4_main_tokens) != 25L) {
  stop(
    "The rendered Stage 4 normal-body label inventory differs.",
    call. = FALSE
  )
}
stage3_attr_nodes <- xml2::xml_find_all(
  stage3_doc,
  "//*[@alt[contains(., 'BA-M')] or @aria-label[contains(., 'BA-M')]]"
)
if (length(stage3_attr_nodes) != 2L) {
  stop(
    "The rendered Stage 3 accessible-label inventory differs.",
    call. = FALSE
  )
}
stage4_source_nodes <- xml2::xml_find_all(
  stage4_doc,
  "//*[@id='quarto-embedded-source-code-modal']//text()[contains(., 'BA-M') or contains(., 'BA-CS-M')]"
)
if (length(stage4_source_nodes) != 17L) {
  stop("The Stage 4 source-modal reflection inventory differs.", call. = FALSE)
}

png_data <- png::readPNG(paths[["figure_png"]], native = FALSE, info = TRUE)
if (!identical(dim(png_data)[1:2], c(3360L, 2640L))) {
  stop("The accepted PNG dimensions differ.", call. = FALSE)
}
png_info <- attr(png_data, "info")
if (max(abs(unname(png_info$dpi) - c(300, 300))) > 0.01) {
  stop("The accepted PNG resolution differs.", call. = FALSE)
}
svg_doc <- xml2::read_xml(paths[["figure_svg"]])
svg_text <- xml2::xml_text(xml2::xml_find_all(
  svg_doc,
  "//*[local-name()='text']"
))
current_svg_labels <- c(
  "BA-M4 FDR p ≥ 0.05",
  "BA-M4 FDR p < 0.05",
  "BA-M6 FDR p < 0.05",
  paste(
    "Orange diamonds test BA-M4 versus zero; black asterisks test BA-M6",
    "versus the equal-site effect."
  ),
  paste(
    "Dotted black line: no difference. Long-dashed blue line:",
    "state-specific equal-site estimate."
  )
)
if (
  !all(vapply(
    current_svg_labels,
    function(value) {
      any(trimws(svg_text) == value)
    },
    logical(1L)
  ))
) {
  stop("The accepted SVG reader-label inventory differs.", call. = FALSE)
}

stage3_pre <- stage3
stage3 <- replace_exact(
  stage3,
  paste0(
    "@fig-main-site-free-work-contrasts shows all 27 site-specific contrasts.\n",
    "`BA-M4` tests each site-specific Free-minus-Work difference against zero,\n",
    "whereas `BA-M6` tests whether that difference departs from the state-specific\n",
    "site-average Free-minus-Work estimate shown by the blue line. The site-average\n",
    "estimate gives all nine sites equal weight and includes the indexed site."
  ),
  paste0(
    "@fig-main-site-free-work-contrasts shows all 27 site-specific contrasts.\n",
    "Each site-specific Free-minus-Work difference was tested against zero and\n",
    "against the state-specific site-average Free-minus-Work estimate shown by the\n",
    "blue line. Orange diamonds identify FDR-retained differences from zero, whereas\n",
    "black asterisks identify FDR-retained departures from the site-average\n",
    "estimate. The site-average estimate gives all nine sites equal weight and\n",
    "includes the indexed site."
  )
)
stage3 <- replace_exact(
  stage3,
  "Three BA-M6 contrasts passed the 27-member FDR family.",
  "Three departures from the site-average estimate passed the 27-member FDR family."
)
stage3 <- replace_exact(
  stage3,
  paste0(
    "Orange filled diamonds mark the five BA-M4 contrasts that differed from zero ",
    "after their FDR adjustment. Black asterisks mark the three BA-M6 contrasts ",
    "that differed from the state-specific site-average Free-minus-Work estimate ",
    "after adjustment across the 27-member family."
  ),
  paste0(
    "Orange filled diamonds mark the five site-specific contrasts that differed ",
    "from zero after their FDR adjustment. Black asterisks mark the three contrasts ",
    "that differed from the state-specific site-average Free-minus-Work estimate ",
    "after adjustment across the 27-member family."
  )
)
stage3 <- replace_exact(
  stage3,
  "Five orange diamonds identify BA-M4 differences from zero.",
  paste(
    "Five orange diamonds identify site-specific Free-minus-Work differences",
    "from zero."
  )
)
stage3 <- replace_exact(
  stage3,
  "Three black asterisks identify BA-M6 differences from the site-average estimate:",
  paste(
    "Three black asterisks identify departures from the site-average",
    "Free-minus-Work estimate:"
  )
)
stage3 <- replace_exact(
  stage3,
  "unless they carry only the orange BA-M4 marker.",
  "unless they carry only the orange difference-from-zero marker."
)

stage4_pre <- stage4
stage4 <- replace_exact(
  stage4,
  paste0(
    "`BA-M6` was calculated from 54 stored state-by-site-by-day-type cell means and\n",
    "their 54 by 54 covariance matrix without refitting the model. Its 27 contrast\n",
    "vectors were applied once. Every point estimate was reconciled in two\n",
    "independent ways: `BA-M4 - BA-M1`, and the Free-day `BA-M5` site deviation\n",
    "minus the Work-day `BA-M5` site deviation. Within each state, the nine\n",
    "deviations from the site-average effect summed to zero to machine tolerance."
  ),
  paste0(
    "The family of site-specific departures from the state-specific site-average\n",
    "Free-minus-Work estimate (`BA-M6`) was calculated from 54 stored\n",
    "state-by-site-by-day-type cell means and their 54 by 54 covariance matrix\n",
    "without refitting the model. Its 27 contrast vectors were applied once. Every\n",
    "point estimate was reconciled in two independent ways: the site-specific\n",
    "Free-minus-Work difference against zero (`BA-M4`) minus the state-specific\n",
    "site-average Free-minus-Work difference (`BA-M1`), and the Free-day site\n",
    "deviation from the site-average adherence estimate (`BA-M5`) minus the\n",
    "corresponding Work-day deviation (`BA-M5`). Within each state, the nine\n",
    "deviations from the site-average effect summed to zero to machine tolerance."
  )
)
stage4 <- replace_exact(
  stage4,
  '#| tbl-cap: "Stored-covariance and component reconciliation for BA-M6."',
  paste0(
    '#| tbl-cap: "Stored-covariance and component reconciliation for ',
    'site-specific departures from the state-specific site-average ',
    'Free-minus-Work estimate (BA-M6)."'
  )
)
stage4 <- replace_exact(
  stage4,
  paste0(
    "  fmt_integer(columns = c(`Stored cell means`, `Reconciled BA-M6 rows`)) |>\n",
    "  fmt_scientific("
  ),
  paste0(
    "  fmt_integer(columns = c(`Stored cell means`, `Reconciled BA-M6 rows`)) |>\n",
    "  cols_label(\n",
    "    `Reconciled BA-M6 rows` =\n",
    "      \"Reconciled site-average-departure rows (BA-M6)\"\n",
    "  ) |>\n",
    "  fmt_scientific("
  )
)
stage4 <- replace_exact(
  stage4,
  '#| tbl-cap: "BA-M6 localizations and coverage-sensitivity identities."',
  paste0(
    '#| tbl-cap: "Site-specific departures from the state-specific ',
    'site-average Free-minus-Work estimate (BA-M6) and ',
    'coverage-sensitivity identities."'
  )
)
stage4 <- replace_exact(
  stage4,
  paste0(
    "5. Keep `BA-M1` through `BA-M6` and `BA-CS-M1` as separate multiplicity\n",
    "   families."
  ),
  paste0(
    "5. Keep the seven multiplicity families listed in @tbl-stage4-multiplicity\n",
    "   separate."
  )
)
stage4 <- replace_exact(
  stage4,
  paste0(
    "6. Reconcile `BA-M6` to the stored means, covariance, `BA-M1`, `BA-M4`, and\n",
    "   `BA-M5` records without refitting a model."
  ),
  paste0(
    "6. Reconcile the site-specific departure from the state-specific site-average\n",
    "   Free-minus-Work estimate (`BA-M6`) to the stored means and covariance, the\n",
    "   site-specific Free-minus-Work difference against zero (`BA-M4`), the\n",
    "   state-specific site-average Free-minus-Work difference (`BA-M1`), and the\n",
    "   site deviations from the day-type-specific site-average adherence estimates\n",
    "   (`BA-M5`) without refitting a model."
  )
)

builder_pre <- builder
builder <- replace_exact(
  builder,
  "BA-M4 FDR p ≥ 0.05",
  "vs zero: FDR p ≥ 0.05",
  expected_count = 6L
)
builder <- replace_exact(
  builder,
  "BA-M4 FDR p < 0.05",
  "vs zero: FDR p < 0.05",
  expected_count = 6L
)
builder <- replace_exact(
  builder,
  "BA-M6 FDR p < 0.05",
  "vs site average: FDR p < 0.05",
  expected_count = 3L
)
builder <- replace_exact(
  builder,
  paste(
    "Orange diamonds test BA-M4 versus zero; black asterisks test BA-M6",
    "versus the equal-site effect."
  ),
  paste(
    "Orange diamonds: differences from zero; black asterisks:",
    "departures from the site average."
  )
)
builder <- replace_exact(
  builder,
  "state-specific equal-site estimate.",
  "state-specific site-average estimate."
)

prospective <- data.frame(
  artifact = c("stage3_qmd", "stage4_qmd", "figure_builder"),
  sha256 = c(text_sha256(stage3), text_sha256(stage4), text_sha256(builder)),
  bytes = c(
    nchar(stage3, type = "bytes"),
    nchar(stage4, type = "bytes"),
    nchar(builder, type = "bytes")
  ),
  stringsAsFactors = FALSE
)

expected_prospective_sha <- c(
  stage3_qmd = "ea8f639a5b58ef591bf4716928ef32db4de68b30e157e2670867a5c0ee2d9c05",
  stage4_qmd = "8fc81d9b28b60a3ab28315b6e83f884e55d2f8cbcb7cb374312414b1922c9c92",
  figure_builder = "7d65e028764d522635438b10cd0573315a32ace1753b8c53762b074164bd05fd"
)
expected_prospective_bytes <- c(
  stage3_qmd = 55601,
  stage4_qmd = 25275,
  figure_builder = 17867
)

if (!identical(prospective$sha256, unname(expected_prospective_sha))) {
  stop("A prospective source SHA-256 differs.", call. = FALSE)
}
if (
  !identical(
    as.numeric(prospective$bytes),
    as.numeric(unname(expected_prospective_bytes))
  )
) {
  stop("A prospective source byte count differs.", call. = FALSE)
}

if (length(extract_regex(stage3, label_pattern)) != 0L) {
  stop(
    "The prospective Stage 3 source retains a BA-M reader label.",
    call. = FALSE
  )
}
if (!identical(extract_links(stage3_pre), extract_links(stage3))) {
  stop("A Stage 3 link target changed.", call. = FALSE)
}
if (!identical(extract_links(stage4_pre), extract_links(stage4))) {
  stop("A Stage 4 link target changed.", call. = FALSE)
}
if (!identical(extract_inline_r(stage3_pre), extract_inline_r(stage3))) {
  stop("A Stage 3 inline R expression changed.", call. = FALSE)
}
if (!identical(extract_inline_r(stage4_pre), extract_inline_r(stage4))) {
  stop("A Stage 4 inline R expression changed.", call. = FALSE)
}
if (!identical(extract_labels(stage3_pre), extract_labels(stage3))) {
  stop("A Stage 3 endpoint label changed.", call. = FALSE)
}
if (!identical(extract_labels(stage4_pre), extract_labels(stage4))) {
  stop("A Stage 4 endpoint label changed.", call. = FALSE)
}
if (
  !identical(extract_numeric_tokens(stage3_pre), extract_numeric_tokens(stage3))
) {
  stop("The Stage 3 numeric-token multiset changed.", call. = FALSE)
}
if (
  !identical(extract_numeric_tokens(stage4_pre), extract_numeric_tokens(stage4))
) {
  stop("The Stage 4 numeric-token multiset changed.", call. = FALSE)
}

stage3_parse_pre <- parse_chunks(stage3_pre)
stage3_parse_post <- parse_chunks(stage3)
stage4_parse_pre <- parse_chunks(stage4_pre)
stage4_parse_post <- parse_chunks(stage4)
message(
  sprintf(
    "Parse audit: Stage 3 %d/%d -> %d/%d; Stage 4 %d/%d -> %d/%d.",
    stage3_parse_pre$chunks,
    stage3_parse_pre$expressions,
    stage3_parse_post$chunks,
    stage3_parse_post$expressions,
    stage4_parse_pre$chunks,
    stage4_parse_pre$expressions,
    stage4_parse_post$chunks,
    stage4_parse_post$expressions
  )
)
if (!identical(stage3_parse_pre, stage3_parse_post)) {
  stop("The Stage 3 R-chunk parse structure changed.", call. = FALSE)
}
if (
  stage4_parse_pre$chunks != stage4_parse_post$chunks ||
    stage4_parse_post$expressions != stage4_parse_pre$expressions
) {
  stop("The Stage 4 R-chunk parse structure changed.", call. = FALSE)
}

if (
  !identical(
    replace_exact(
      stage3,
      paste0(
        "@fig-main-site-free-work-contrasts shows all 27 site-specific contrasts.\n",
        "Each site-specific Free-minus-Work difference was tested against zero and\n",
        "against the state-specific site-average Free-minus-Work estimate shown by the\n",
        "blue line. Orange diamonds identify FDR-retained differences from zero, whereas\n",
        "black asterisks identify FDR-retained departures from the site-average\n",
        "estimate. The site-average estimate gives all nine sites equal weight and\n",
        "includes the indexed site."
      ),
      paste0(
        "@fig-main-site-free-work-contrasts shows all 27 site-specific contrasts.\n",
        "`BA-M4` tests each site-specific Free-minus-Work difference against zero,\n",
        "whereas `BA-M6` tests whether that difference departs from the state-specific\n",
        "site-average Free-minus-Work estimate shown by the blue line. The site-average\n",
        "estimate gives all nine sites equal weight and includes the indexed site."
      )
    ) |>
      replace_exact(
        "Three departures from the site-average estimate passed the 27-member FDR family.",
        "Three BA-M6 contrasts passed the 27-member FDR family."
      ) |>
      replace_exact(
        paste0(
          "Orange filled diamonds mark the five site-specific contrasts that differed ",
          "from zero after their FDR adjustment. Black asterisks mark the three contrasts ",
          "that differed from the state-specific site-average Free-minus-Work estimate ",
          "after adjustment across the 27-member family."
        ),
        paste0(
          "Orange filled diamonds mark the five BA-M4 contrasts that differed from zero ",
          "after their FDR adjustment. Black asterisks mark the three BA-M6 contrasts ",
          "that differed from the state-specific site-average Free-minus-Work estimate ",
          "after adjustment across the 27-member family."
        )
      ) |>
      replace_exact(
        paste(
          "Five orange diamonds identify site-specific Free-minus-Work differences",
          "from zero."
        ),
        "Five orange diamonds identify BA-M4 differences from zero."
      ) |>
      replace_exact(
        paste(
          "Three black asterisks identify departures from the site-average",
          "Free-minus-Work estimate:"
        ),
        "Three black asterisks identify BA-M6 differences from the site-average estimate:"
      ) |>
      replace_exact(
        "unless they carry only the orange difference-from-zero marker.",
        "unless they carry only the orange BA-M4 marker."
      ),
    stage3_pre
  )
) {
  stop("The Stage 3 exact reverse proof failed.", call. = FALSE)
}

stage4_reverse <- stage4 |>
  replace_exact(
    paste0(
      "The family of site-specific departures from the state-specific site-average\n",
      "Free-minus-Work estimate (`BA-M6`) was calculated from 54 stored\n",
      "state-by-site-by-day-type cell means and their 54 by 54 covariance matrix\n",
      "without refitting the model. Its 27 contrast vectors were applied once. Every\n",
      "point estimate was reconciled in two independent ways: the site-specific\n",
      "Free-minus-Work difference against zero (`BA-M4`) minus the state-specific\n",
      "site-average Free-minus-Work difference (`BA-M1`), and the Free-day site\n",
      "deviation from the site-average adherence estimate (`BA-M5`) minus the\n",
      "corresponding Work-day deviation (`BA-M5`). Within each state, the nine\n",
      "deviations from the site-average effect summed to zero to machine tolerance."
    ),
    paste0(
      "`BA-M6` was calculated from 54 stored state-by-site-by-day-type cell means and\n",
      "their 54 by 54 covariance matrix without refitting the model. Its 27 contrast\n",
      "vectors were applied once. Every point estimate was reconciled in two\n",
      "independent ways: `BA-M4 - BA-M1`, and the Free-day `BA-M5` site deviation\n",
      "minus the Work-day `BA-M5` site deviation. Within each state, the nine\n",
      "deviations from the site-average effect summed to zero to machine tolerance."
    )
  ) |>
  replace_exact(
    paste0(
      '#| tbl-cap: "Stored-covariance and component reconciliation for ',
      'site-specific departures from the state-specific site-average ',
      'Free-minus-Work estimate (BA-M6)."'
    ),
    '#| tbl-cap: "Stored-covariance and component reconciliation for BA-M6."'
  ) |>
  replace_exact(
    paste0(
      "  fmt_integer(columns = c(`Stored cell means`, `Reconciled BA-M6 rows`)) |>\n",
      "  cols_label(\n",
      "    `Reconciled BA-M6 rows` =\n",
      "      \"Reconciled site-average-departure rows (BA-M6)\"\n",
      "  ) |>\n",
      "  fmt_scientific("
    ),
    paste0(
      "  fmt_integer(columns = c(`Stored cell means`, `Reconciled BA-M6 rows`)) |>\n",
      "  fmt_scientific("
    )
  ) |>
  replace_exact(
    paste0(
      '#| tbl-cap: "Site-specific departures from the state-specific ',
      'site-average Free-minus-Work estimate (BA-M6) and ',
      'coverage-sensitivity identities."'
    ),
    '#| tbl-cap: "BA-M6 localizations and coverage-sensitivity identities."'
  ) |>
  replace_exact(
    paste0(
      "5. Keep the seven multiplicity families listed in @tbl-stage4-multiplicity\n",
      "   separate."
    ),
    paste0(
      "5. Keep `BA-M1` through `BA-M6` and `BA-CS-M1` as separate multiplicity\n",
      "   families."
    )
  ) |>
  replace_exact(
    paste0(
      "6. Reconcile the site-specific departure from the state-specific site-average\n",
      "   Free-minus-Work estimate (`BA-M6`) to the stored means and covariance, the\n",
      "   site-specific Free-minus-Work difference against zero (`BA-M4`), the\n",
      "   state-specific site-average Free-minus-Work difference (`BA-M1`), and the\n",
      "   site deviations from the day-type-specific site-average adherence estimates\n",
      "   (`BA-M5`) without refitting a model."
    ),
    paste0(
      "6. Reconcile `BA-M6` to the stored means, covariance, `BA-M1`, `BA-M4`, and\n",
      "   `BA-M5` records without refitting a model."
    )
  )
if (!identical(stage4_reverse, stage4_pre)) {
  stop("The Stage 4 exact reverse proof failed.", call. = FALSE)
}

builder_reverse <- builder |>
  replace_exact(
    "vs zero: FDR p ≥ 0.05",
    "BA-M4 FDR p ≥ 0.05",
    expected_count = 6L
  ) |>
  replace_exact(
    "vs zero: FDR p < 0.05",
    "BA-M4 FDR p < 0.05",
    expected_count = 6L
  ) |>
  replace_exact(
    "vs site average: FDR p < 0.05",
    "BA-M6 FDR p < 0.05",
    expected_count = 3L
  ) |>
  replace_exact(
    paste(
      "Orange diamonds: differences from zero; black asterisks:",
      "departures from the site average."
    ),
    paste(
      "Orange diamonds test BA-M4 versus zero; black asterisks test BA-M6",
      "versus the equal-site effect."
    )
  ) |>
  replace_exact(
    "state-specific site-average estimate.",
    "state-specific equal-site estimate."
  )
if (!identical(builder_reverse, builder_pre)) {
  stop("The Figure 3 builder exact reverse proof failed.", call. = FALSE)
}

inventory <- utils::read.csv(paths[["audit_inventory"]], check.names = FALSE)
display_audit <- utils::read.csv(
  paths[["display_candidate_audit"]],
  check.names = FALSE
)
matrix <- utils::read.csv(paths[["change_matrix"]], check.names = FALSE)
if (
  nrow(inventory) != 14L ||
    anyDuplicated(inventory$audit_id) ||
    nrow(display_audit) != 10L ||
    anyDuplicated(display_audit$check_id) ||
    nrow(matrix) != 12L ||
    anyDuplicated(matrix$change_id)
) {
  stop("The durable audit or change matrix is incomplete.", call. = FALSE)
}

candidate_expectation <- data.frame(
  artifact = c("PNG", "SVG"),
  sha256 = c(
    "2467061413fc1da4834eb92072598f5af46526631e573401bbe3fa874eb4695a",
    "8e5eee7e55b3e99953de87f6f00698c28903f5445db1bf01e15c662851123e8d"
  ),
  bytes = c(348627, 32073),
  stringsAsFactors = FALSE
)

cat(
  sprintf(
    paste0(
      "BROWN_BA_M_READER_LABEL_REOPENING=PASS ",
      "audit=%d display=%d matrix=%d stage3=%d_chunks/%d_expr ",
      "stage4=%d_chunks/%d_expr current_labels=%d/%d ",
      "candidate=%s/%s\n"
    ),
    nrow(inventory),
    nrow(display_audit),
    nrow(matrix),
    stage3_parse_post$chunks,
    stage3_parse_post$expressions,
    stage4_parse_post$chunks,
    stage4_parse_post$expressions,
    length(stage3_labels),
    length(stage4_labels),
    substr(candidate_expectation$sha256[[1L]], 1L, 12L),
    substr(candidate_expectation$sha256[[2L]], 1L, 12L)
  )
)
print(prospective, row.names = FALSE)
