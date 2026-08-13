#!/usr/bin/env Rscript

# Focused no-refit verification of the H06_daily preparation companion.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c("digest", "dplyr", "readr", "xml2")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf("Missing synchronized packages: %s", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}

assert <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

read_project_csv <- function(relative_path) {
  readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE,
    na = c("", "NA")
  )
}

verify_identity_manifest <- function(manifest, label) {
  paths <- file.path(root, manifest$relative_path)
  assert(
    all(file.exists(paths)) &&
      identical(unname(vapply(paths, sha256, character(1L))), manifest$sha256) &&
      identical(as.numeric(file.info(paths)$size), manifest$bytes),
    paste0(label, " contains a missing or changed identity")
  )
}

extract_r_chunks <- function(lines) {
  in_chunk <- FALSE
  chunks <- character()
  for (line in lines) {
    if (!in_chunk && grepl("^```[\\{]r([,}])", line)) {
      in_chunk <- TRUE
      next
    }
    if (in_chunk && identical(trimws(line), "```")) {
      in_chunk <- FALSE
      next
    }
    if (in_chunk) {
      chunks <- c(chunks, line)
    }
  }
  paste(chunks, collapse = "\n")
}

assert(
  identical(as.character(getRversion()), "4.6.1"),
  "The H06_daily preparation verification requires R 4.6.1"
)

source_dir <- "artifacts/11_source_data/H06_daily"
manifest_dir <- "artifacts/12_manifests/H06_daily"
input_provenance <- read_project_csv(file.path(
  source_dir,
  "H06_daily_preparation_input_provenance.csv"
))
metrics <- read_project_csv(file.path(
  source_dir,
  "H06_daily_preparation_metric_registry.csv"
))
predictors <- read_project_csv(file.path(
  source_dir,
  "H06_daily_preparation_predictor_registry.csv"
))
routes <- read_project_csv(file.path(
  source_dir,
  "H06_daily_preparation_model_routes.csv"
))
samples <- read_project_csv(file.path(
  source_dir,
  "H06_daily_preparation_exact_samples.csv"
))
sample_roles <- read_project_csv(file.path(
  source_dir,
  "H06_daily_preparation_sample_role_summary.csv"
))
predictor_support <- read_project_csv(file.path(
  source_dir,
  "H06_daily_preparation_primary_predictor_support.csv"
))
site_support <- read_project_csv(file.path(
  source_dir,
  "H06_daily_preparation_primary_site_support.csv"
))
multiplicity <- read_project_csv(file.path(
  source_dir,
  "H06_daily_preparation_multiplicity_families.csv"
))
diagnostics <- read_project_csv(file.path(
  source_dir,
  "H06_daily_preparation_diagnostic_summary.csv"
))
temporal <- read_project_csv(file.path(
  source_dir,
  "H06_daily_preparation_temporal_support.csv"
))

source_manifest <- read_project_csv(file.path(
  manifest_dir,
  "H06_daily_preparation_source_data_manifest.csv"
))
software_manifest <- read_project_csv(file.path(
  manifest_dir,
  "H06_daily_preparation_software_manifest.csv"
))
figure_qa <- read_project_csv(file.path(
  manifest_dir,
  "H06_daily_preparation_figure_readability_qa.csv"
))
render_qa <- read_project_csv(file.path(
  manifest_dir,
  "H06_daily_preparation_render_qa.csv"
))
output_manifest <- read_project_csv(file.path(
  manifest_dir,
  "H06_daily_preparation_output_manifest.csv"
))
report_manifest <- read_project_csv(
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation_report_manifest.csv"
)

assert(
  nrow(input_provenance) == 19L &&
    all(input_provenance$verification_status == "PASS") &&
    all(input_provenance$expected_sha256 == input_provenance$observed_sha256),
  "The exact H06_daily preparation input contract is incomplete or changed"
)
verify_identity_manifest(source_manifest, "The preparation source-data manifest")
verify_identity_manifest(output_manifest, "The preparation output manifest")
verify_identity_manifest(report_manifest, "The preparation report manifest")
assert(
  nrow(source_manifest) == 17L &&
    nrow(software_manifest) == 14L &&
    nrow(figure_qa) == 1L &&
    nrow(render_qa) == 11L &&
    nrow(output_manifest) == 31L &&
    nrow(report_manifest) == 15L &&
    !anyDuplicated(source_manifest$relative_path) &&
    !anyDuplicated(output_manifest$relative_path) &&
    !anyDuplicated(report_manifest$relative_path) &&
    all(render_qa$status %in% c("PASS", "DISCLOSED_LIMITATION")) &&
    sum(render_qa$status == "DISCLOSED_LIMITATION") == 1L &&
    any(software_manifest$component == "R" & software_manifest$version == "4.6.1") &&
    any(software_manifest$component == "Quarto" & software_manifest$version == "1.9.37"),
  "A preparation manifest or QA record is malformed"
)

assert(
  nrow(metrics) == 15L &&
    identical(as.integer(metrics$metric_slot), 1:15) &&
    all(metrics$analysis_unit == "participant-day") &&
    nrow(predictors) == 3L &&
    nrow(routes) == 15L &&
    nrow(samples) == 522L &&
    nrow(sample_roles) == 12L &&
    nrow(predictor_support) == 75L &&
    nrow(site_support) == 405L &&
    nrow(multiplicity) == 12L &&
    all(multiplicity$named_slots == 15L) &&
    all(multiplicity$named_na_slots == 1L) &&
    nrow(diagnostics) == 25L &&
    nrow(temporal) == 6L,
  "A preparation registry, sample grid, family, or diagnostic summary is incomplete"
)

primary_mean_work <- samples |>
  dplyr::filter(
    .data$run_id == "primary__near_eye__all_available",
    .data$metric_slot == 1L,
    .data$predictor_id == "work_free_day"
  )
primary_mder_work <- samples |>
  dplyr::filter(
    .data$run_id == "primary__near_eye__all_available",
    .data$metric_slot == 15L,
    .data$predictor_id == "work_free_day"
  )
primary_temporal <- temporal |>
  dplyr::filter(.data$run_id == "primary__near_eye__all_available")
overall_diagnostic <- diagnostics |>
  dplyr::filter(.data$domain == "Overall H01-aligned cell status")
visual_diagnostic <- diagnostics |>
  dplyr::filter(.data$domain == "Visual residual review")
assert(
  nrow(primary_mean_work) == 1L &&
    primary_mean_work$participant_days == 784L &&
    primary_mean_work$participants == 141L &&
    primary_mean_work$sites == 9L &&
    nrow(primary_mder_work) == 1L &&
    primary_mder_work$participant_days == 679L &&
    primary_mder_work$participants == 136L &&
    primary_mder_work$sites == 9L &&
    nrow(primary_temporal) == 1L &&
    primary_temporal$observations_30_minute == 33057L &&
    primary_temporal$participant_days == 715L &&
    primary_temporal$participants == 137L &&
    primary_temporal$sites == 9L &&
    isTRUE(all.equal(primary_temporal$rho, 0.5787385, tolerance = 1e-7)) &&
    nrow(overall_diagnostic) == 1L &&
    overall_diagnostic$cells == 468L &&
    overall_diagnostic$reader_classification == "Acceptable with limitations" &&
    nrow(visual_diagnostic) == 1L &&
    visual_diagnostic$cells == 468L &&
    visual_diagnostic$reader_classification == "Review limitation",
  "An exact fitted-sample or stored diagnostic assertion changed"
)

qmd_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd"
)
html_path <- sub("[.]qmd$", ".html", qmd_path)
qmd_lines <- readLines(qmd_path, warn = FALSE)
qmd <- paste(qmd_lines, collapse = "\n")
executable_r <- extract_r_chunks(qmd_lines)
forbidden_calls <- c(
  "lmer\\s*\\(", "glmmTMB\\s*\\(", "bam\\s*\\(", "gam\\s*\\(",
  "lm\\s*\\(", "predict\\s*\\(", "anova\\s*\\(", "p[.]adjust\\s*\\(",
  "boot\\s*\\(", "simulate\\s*\\(", "acf\\s*\\("
)
assert(
  !any(vapply(
    forbidden_calls,
    function(pattern) grepl(pattern, executable_r, perl = TRUE),
    logical(1L)
  )),
  "The preparation QMD contains a prohibited analytical call in an executable R chunk"
)
assert(
    grepl("callout-note", qmd, fixed = TRUE) &&
    grepl("H06 daily-metric results report", qmd, fixed = TRUE) &&
    grepl("Every displayed interval is pointwise", qmd, fixed = TRUE) &&
    grepl("simultaneous confidence band was constructed", qmd, fixed = TRUE),
  "A required preparation companion statement is missing"
)

html <- xml2::read_html(html_path)
main <- xml2::xml_find_first(html, "//main")
main_text <- xml2::xml_text(main)
tables <- xml2::xml_find_all(html, "//main//table")
images <- xml2::xml_find_all(html, "//main//img")
image_alt <- xml2::xml_attr(images, "alt")
image_src <- xml2::xml_attr(images, "src")
note_callouts <- xml2::xml_find_all(
  html,
  "//main//*[contains(concat(' ', normalize-space(@class), ' '), ' callout-note ')]"
)
mermaid <- xml2::xml_find_all(
  html,
  "//main//*[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
)
assert(
  length(tables) == 17L &&
    length(images) == 1L &&
    startsWith(image_src, "data:image/png;base64,") &&
    nzchar(image_alt) &&
    length(note_callouts) == 1L &&
    length(mermaid) == 1L &&
    !grepl("Stage 4", main_text, fixed = TRUE) &&
    !grepl("H06-D-G", main_text, fixed = TRUE) &&
    !grepl("coordinator", main_text, fixed = TRUE) &&
    !grepl("worker", main_text, fixed = TRUE),
  "The rendered preparation companion failed a reader-facing structural check"
)

# The preparation-only run must preserve the accepted complementary results.
accepted_result_pins <- c(
  "notebooks/hypotheses/H06_daily.qmd" =
    "0318fd6cf874380631296d35095486b9de7f987a9779e4dc5d59c5a635a8c3dc",
  "notebooks/hypotheses/H06_daily.html" =
    "5a20c0680011be17111f72bb6b15aed6a4f4700c8866a13ea6dcf49a589fcce3",
  "audit/hypotheses/H06_daily/H06_daily_stage3_revision_gate.md" =
    "733dd1dd4c57bfdb6df7bf10e69e635455c451373c8dd0f6e3060c12b6e3884e"
)
assert(
  identical(
    unname(vapply(file.path(root, names(accepted_result_pins)), sha256, character(1L))),
    unname(accepted_result_pins)
  ),
  "An accepted H06_daily results-report identity changed"
)

cat(
  paste0(
    "PASS: H06_daily preparation companion verified under R ",
    getRversion(), ": 19 pins, 15 metrics, 522 fitted-sample records, ",
    "12 complete 15-slot families, 17 compact tables, one embedded figure, ",
    "31 output identities, and no scientific recomputation.\n"
  )
)
