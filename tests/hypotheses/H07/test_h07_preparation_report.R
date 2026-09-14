# Structural, source-data, display, and provenance checks for the H07
# analysis-preparation companion. These checks never fit or refit models.

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
source(file.path(
  root,
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
))

paths <- preparation_companion_paths(root, "H07")
required <- unlist(paths, use.names = FALSE)
stopifnot(all(file.exists(required)))
stopifnot(identical(
  read_file_bytes(paths$qmd),
  read_file_bytes(paths$rendered_qmd)
))

qmd_lines <- readLines(paths$qmd, warn = FALSE, encoding = "UTF-8")
qmd <- paste(qmd_lines, collapse = "\n")
qmd_compact <- gsub("[[:space:]]+", " ", qmd)
calls <- executable_r_call_names(qmd_lines)
forbidden_calls <- c(
  "mgcv::gam", "mgcv::bam", "gam", "bam", "stats::predict", "predict",
  "stats::simulate", "simulate", "boot::boot", "boot",
  "gratia::derivatives", "derivatives", "h07_stage2_fit_checkpoint",
  "h07_revised_derivatives", "h07_derivative_draws",
  "h07_stage2_tweedie_pilot"
)
stopifnot(length(intersect(calls, forbidden_calls)) == 0L)

stopifnot(
  grepl("flowchart TD", qmd_compact, fixed = TRUE),
  grepl("../../../notebooks/hypotheses/H07.html", qmd_compact, fixed = TRUE),
  grepl("gap-timing-unaware dataset", qmd_compact, fixed = TRUE),
  grepl("time-sensitive primary metric dataset", qmd_compact, fixed = TRUE),
  grepl("100 equally spaced", qmd_compact, fixed = TRUE),
  grepl("Central finite differences use an increment of 0.01 h", qmd_compact,
    fixed = TRUE
  ),
  grepl("pointwise 95%", qmd_compact, fixed = TRUE),
  grepl("every later point through the recorded maximum", qmd_compact,
    fixed = TRUE
  ),
  grepl("not a ceiling claim", qmd_compact, fixed = TRUE),
  grepl("Absolute latitude is constant within every site", qmd_compact,
    fixed = TRUE
  ),
  grepl("No independent temperature", qmd_compact, fixed = TRUE),
  grepl("discrete = FALSE", qmd_compact, fixed = TRUE),
  grepl("not a `bam()` fit", qmd_compact, fixed = TRUE),
  grepl("METRIC-011", qmd_compact, fixed = TRUE),
  grepl("::: {.callout-note", qmd_compact, fixed = TRUE),
  !grepl("::: {.callout-warning", qmd_compact, fixed = TRUE),
  !grepl("::: {.callout-important", qmd_compact, fixed = TRUE)
)

normalize_formula <- function(x) {
  gsub("[[:space:]]+", " ", trimws(x))
}
expected_formulas <- c(
  "response_value ~ s(site, bs = \"re\") + s(site_participant, bs = \"re\")",
  paste(
    "response_value ~ abs_latitude_deg * photoperiod_hours +",
    "s(site, bs = \"re\") + s(site_participant, bs = \"re\")"
  ),
  paste(
    "response_value ~ te(abs_latitude_deg, photoperiod_hours,",
    "k = c(4, 5), bs = c(\"tp\", \"tp\")) +",
    "s(site, bs = \"re\") + s(site_participant, bs = \"re\")"
  ),
  paste(
    "response_value ~ te(abs_latitude_deg, photoperiod_hours,",
    "k = c(5, 8), bs = c(\"tp\", \"tp\")) +",
    "s(site, bs = \"re\") + s(site_participant, bs = \"re\")"
  ),
  paste(
    "response_value ~ te(abs_latitude_deg, photoperiod_hours,",
    "k = c(4, 5), bs = c(\"tp\", \"tp\")) + site +",
    "s(site_participant, bs = \"re\")"
  ),
  paste(
    "response_value ~ photoperiod_hours + s(site, bs = \"re\") +",
    "s(site_participant, bs = \"re\")"
  ),
  paste(
    "response_value ~ s(photoperiod_hours, k = 6, bs = \"tp\") +",
    "s(site, bs = \"re\") + s(site_participant, bs = \"re\")"
  ),
  paste(
    "response_value ~ s(photoperiod_hours, k = 10, bs = \"tp\") +",
    "s(site, bs = \"re\") + s(site_participant, bs = \"re\")"
  ),
  paste(
    "response_value ~ s(photoperiod_hours, k = 6, bs = \"tp\") + site +",
    "s(site_participant, bs = \"re\")"
  )
)
formula_registry <- readr::read_csv(
  file.path(
    root,
    "artifacts/11_source_data/H07/preparation/",
    "H07_preparation_formula_registry.csv"
  ),
  show_col_types = FALSE
)
stopifnot(
  nrow(formula_registry) == 9L,
  !anyDuplicated(formula_registry$model_id),
  identical(
    normalize_formula(formula_registry$formula),
    normalize_formula(expected_formulas)
  )
)

document <- xml2::read_html(paths$html)
main <- xml2::xml_find_first(document, "//main[@id='quarto-document-content']")
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)
stopifnot(
  grepl("H07 analysis preparation and provenance", main_text, fixed = TRUE),
  grepl("139–141 participants", main_text, fixed = TRUE),
  grepl("655–816 participant-days", main_text, fixed = TRUE),
  grepl("153–154 participants", main_text, fixed = TRUE),
  grepl("743–902 participant-days", main_text, fixed = TRUE),
  grepl("All 18 reported photoperiod-smooth fits converged", main_text,
    fixed = TRUE
  ),
  grepl("three near-eye and one chest", main_text, fixed = TRUE),
  grepl("approximately 0.9985–0.9988", main_text, fixed = TRUE),
  grepl("does not support a distinct latitude effect", main_text,
    fixed = TRUE
  ),
  !grepl("Execution halted", main_text, fixed = TRUE)
)

xml2::xml_remove(xml2::xml_find_all(
  main,
  paste0(
    ".//*[contains(concat(' ', normalize-space(@class), ' '),",
    " ' sourceCode ') or self::script or self::style]"
  )
))
reader_text <- xml2::xml_text(main)
forbidden_reader_patterns <- c(
  "\\bStep\\s+[0-9]+\\b",
  "\\bStage\\s+[0-9]+\\b",
  "\\bcoordinat(?:or|ing) task\\b",
  "\\bworker task\\b",
  "\\bworker scope\\b",
  "\\bauthor approval\\b",
  "\\bapproval gate\\b",
  "\\btask ownership\\b",
  "\\bmigration history\\b",
  "\\bV0 analysis\\b",
  "\\bbout\\b"
)
stopifnot(!any(vapply(
  forbidden_reader_patterns,
  grepl,
  logical(1),
  x = reader_text,
  ignore.case = TRUE,
  perl = TRUE
)))

images <- xml2::xml_find_all(main, ".//figure//img")
captions <- xml2::xml_find_all(main, ".//figure/figcaption")
stopifnot(
  length(images) >= 2L,
  length(captions) >= 2L,
  all(nzchar(xml2::xml_attr(images, "alt"))),
  all(nzchar(trimws(xml2::xml_text(captions))))
)

gt_tables <- xml2::xml_find_all(
  main,
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
stopifnot(length(gt_tables) >= 21L)

source_data_contract <- c(
  "H07_preparation_metric_contract.csv" = 9L,
  "H07_preparation_input_identities.csv" = 4L,
  "H07_preparation_frame_integrity.csv" = 18L,
  "H07_preparation_sample_support.csv" = 18L,
  "H07_preparation_site_support.csv" = 153L,
  "H07_preparation_site_photoperiod_ranges.csv" = 17L,
  "H07_preparation_diagnostic_summary.csv" = 2L,
  "H07_preparation_pattern_summary.csv" = 18L,
  "H07_preparation_formula_registry.csv" = 9L
)
source_dir <- file.path(root, "artifacts/11_source_data/H07/preparation")
for (filename in names(source_data_contract)) {
  data <- readr::read_csv(
    file.path(source_dir, filename),
    show_col_types = FALSE
  )
  stopifnot(nrow(data) == unname(source_data_contract[[filename]]))
}

input_identities <- readr::read_csv(
  file.path(source_dir, "H07_preparation_input_identities.csv"),
  show_col_types = FALSE
)
frame_integrity <- readr::read_csv(
  file.path(source_dir, "H07_preparation_frame_integrity.csv"),
  show_col_types = FALSE
)
sample_support <- readr::read_csv(
  file.path(source_dir, "H07_preparation_sample_support.csv"),
  show_col_types = FALSE
)
diagnostic_summary <- readr::read_csv(
  file.path(source_dir, "H07_preparation_diagnostic_summary.csv"),
  show_col_types = FALSE
)
pattern_summary <- readr::read_csv(
  file.path(source_dir, "H07_preparation_pattern_summary.csv"),
  show_col_types = FALSE
)
metric011_summary <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H07/",
    "H07_METRIC-011_reconciliation_summary.csv"
  ),
  show_col_types = FALSE
)
stopifnot(
  all(input_identities$identity_status == "PASS"),
  all(frame_integrity$frame_identity == "PASS"),
  all(frame_integrity$schema_complete),
  all(frame_integrity$duplicate_row_keys == 0L),
  all(frame_integrity$latitude_constant_within_site),
  all(frame_integrity$stored_sample_counts_match),
  all(frame_integrity$overall_status == "PASS"),
  identical(range(sample_support$participants[sample_support$placement == "near_eye"]),
    c(139, 141)
  ),
  identical(range(sample_support$participant_days[sample_support$placement == "near_eye"]),
    c(655, 816)
  ),
  identical(range(sample_support$participants[sample_support$placement == "chest"]),
    c(153, 154)
  ),
  identical(range(sample_support$participant_days[sample_support$placement == "chest"]),
    c(743, 902)
  ),
  all(sample_support$participant_days == sample_support$observations),
  identical(
    diagnostic_summary$basis_dimension_flags[
      diagnostic_summary$placement == "near_eye"
    ],
    3
  ),
  identical(
    diagnostic_summary$basis_dimension_flags[
      diagnostic_summary$placement == "chest"
    ],
    1
  ),
  sum(
    pattern_summary$derivative_defined_pattern &
      pattern_summary$placement == "near_eye"
  ) == 6L,
  sum(
    pattern_summary$derivative_defined_pattern &
      pattern_summary$placement == "chest"
  ) == 7L,
  all(metric011_summary$status == "PASS"),
  metric011_summary$observed[
    metric011_summary$check_id == "SCIENTIFIC_CONCLUSION_CHANGED"
  ] == "FALSE",
  metric011_summary$observed[
    metric011_summary$check_id == "BOUNDED_ARTIFACT_APPLY"
  ] == metric011_summary$expected[
    metric011_summary$check_id == "BOUNDED_ARTIFACT_APPLY"
  ]
)

qa <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H07/H07_figure_readability_qa.csv"
  ),
  show_col_types = FALSE
)
proof_index <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H07/H07_figure_A4_proof_index.csv"
  ),
  show_col_types = FALSE
)
qa_checks <- c(
  "clipping_or_cropping", "overlaps", "text_shape_and_distortion",
  "wrapping_and_units", "important_text_readable",
  "legend_and_data_region_balance", "marks_and_lines_distinguishable",
  "caption_and_alt_text_present"
)
stopifnot(
  nrow(qa) == 4L,
  !anyDuplicated(qa$figure_id),
  all(qa$overall_status == "PASS"),
  all(qa$visual_status == "PASS"),
  all(qa$typography_status == "PASS_BY_CALCULATION"),
  all(qa$intended_display_width_mm == 170),
  all(qa$effective_final_essential_text_pt >= 7),
  all(qa$effective_final_central_text_pt >= 7),
  all(qa$a4_page_width_mm == 210),
  all(qa$a4_page_height_mm == 297),
  all(qa$a4_side_margin_mm == 20),
  all(vapply(qa[qa_checks], function(value) all(value == "PASS"), logical(1))),
  nrow(proof_index) == 6L,
  identical(as.integer(proof_index$proof_page), 1:6),
  all(file.exists(file.path(root, proof_index$proof_path)))
)

result_document <- xml2::read_html(paths$result_html)
result_main <- xml2::xml_find_first(
  result_document,
  "//main[@id='quarto-document-content']"
)
prep_href <- paste0(
  "../../audit/hypotheses/H07/",
  "H07_analysis_preparation.html"
)
prep_links <- xml2::xml_find_all(
  result_main,
  paste0(".//a[contains(@href, '", prep_href, "')]")
)
stopifnot(length(prep_links) >= 1L)

manifest <- readr::read_csv(paths$manifest, show_col_types = FALSE)
stopifnot(
  !anyDuplicated(manifest$path),
  all(nchar(manifest$sha256) == 64L),
  all(nzchar(manifest$r_version)),
  all(file.exists(file.path(root, manifest$path)))
)
manifest_files <- file.path(root, manifest$path)
stopifnot(
  all(unname(file.info(manifest_files)$size) == manifest$bytes),
  all(vapply(manifest_files, artifact_sha256, character(1)) == manifest$sha256)
)

profile_lines <- readLines(paths$quarto_profile, warn = FALSE, encoding = "UTF-8")
profile_integrated <- any(
  trimws(profile_lines) ==
    "- audit/hypotheses/H07/H07_analysis_preparation.qmd"
)

if (profile_integrated) {
  verification <- verify_hypothesis_preparation_companion(
    root = root,
    hypothesis_id = "H07",
    min_figures = 2L,
    min_gt_tables = 21L,
    extra_forbidden_calls = c(
      "gratia::derivatives", "derivatives", "h07_stage2_fit_checkpoint",
      "h07_revised_derivatives", "h07_derivative_draws",
      "h07_stage2_tweedie_pilot"
    )
  )
  stopifnot(
    verification$figures >= 2L,
    verification$gt_tables >= 21L,
    verification$manifest_identities >= 100L,
    isTRUE(verification$source_copy_identical)
  )
  message("H07 preparation companion verified after shared-site integration")
} else {
  request_path <- file.path(
    root,
    "audit/handoffs/H07_shared_change_request.md"
  )
  stopifnot(file.exists(request_path))
  request <- paste(readLines(request_path, warn = FALSE), collapse = "\n")
  stopifnot(
    grepl("H07_analysis_preparation.qmd", request, fixed = TRUE),
    grepl("shared integration pending", request, ignore.case = TRUE)
  )
  message(
    "H07-owned preparation companion verified before shared-site integration: ",
    length(images), " figures, ", length(gt_tables), " gt tables, ",
    nrow(manifest), " manifest identities, and a byte-identical source copy"
  )
}
