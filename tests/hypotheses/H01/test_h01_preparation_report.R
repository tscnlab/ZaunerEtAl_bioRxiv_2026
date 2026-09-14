#!/usr/bin/env Rscript

# H01-specific checks layered on the shared preparation-page contract.

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

stopifnot(identical(as.character(getRversion()), "4.6.1"))

source_only <- tolower(
  Sys.getenv("H01_PREPARATION_SOURCE_ONLY", unset = "false")
) %in% c("1", "true", "yes")
paths <- preparation_companion_paths(root, "H01")
source_required <- c(
  paths$qmd,
  paths$result_qmd,
  paths$manifest,
  paths$quarto_profile
)
stopifnot(all(file.exists(source_required)))

qmd_lines <- readLines(paths$qmd, warn = FALSE, encoding = "UTF-8")
qmd <- paste(qmd_lines, collapse = "\n")
result_qmd <- paste(
  readLines(paths$result_qmd, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)

extra_forbidden_calls <- c(
  "h01_fit_model",
  "h01_fit_metric_models",
  "h01_model_tests",
  "h01_site_summaries",
  "h01_prediction_bounds",
  "h01_residual_diagnostics",
  "h01_participant_influence",
  "h01_latitude_leave_one_site_out",
  "h01_fit_random_site_summary",
  "h01_simulate_response",
  "h01_bootstrap_one",
  "h01_bootstrap_r2"
)
default_forbidden_calls <- c(
  "mgcv::gam", "mgcv::bam", "gam", "bam",
  "lme4::lmer", "lmer", "lme4::glmer", "glmer",
  "glmmTMB::glmmTMB", "glmmTMB", "brms::brm", "brm",
  "stats::predict", "predict", "stats::simulate", "simulate",
  "boot::boot", "boot", "emmeans::emmeans", "emmeans"
)
executable_calls <- executable_r_call_names(qmd_lines)
stopifnot(
  length(intersect(
    executable_calls,
    c(default_forbidden_calls, extra_forbidden_calls)
  )) == 0L
)

table_labels <- regmatches(
  qmd,
  gregexpr("(?<=#\\| label: )tbl-h01-[a-z0-9-]+", qmd, perl = TRUE)
)[[1]]
figure_labels <- regmatches(
  qmd,
  gregexpr("(?<=#\\| label: )fig-h01-[a-z0-9-]+", qmd, perl = TRUE)
)[[1]]
result_link <- "../../../notebooks/hypotheses/H01.qmd"
result_anchor_link <- paste0(result_link, "#h01-preregistration-deviations")
companion_link <- "../../audit/hypotheses/H01/H01_analysis_preparation.qmd"
stopifnot(
  length(table_labels) == 20L,
  !anyDuplicated(table_labels),
  length(figure_labels) == 2L,
  !anyDuplicated(figure_labels),
  grepl("flowchart TD", qmd, fixed = TRUE),
  grepl("h01_input_contract(root)", qmd, fixed = TRUE),
  grepl("calendar-day cumulative", qmd, ignore.case = TRUE),
  grepl("strictly after 16:00", qmd, fixed = TRUE),
  grepl("gap-timing-unaware dataset", qmd, fixed = TRUE),
  grepl("four separate complete 17-test", qmd, fixed = TRUE),
  grepl("H01_preparation_fitted_sample_support.csv", qmd, fixed = TRUE),
  grepl("H01_preparation_model_frame_retention.csv", qmd, fixed = TRUE),
  grepl("run_h01_models.R", qmd, fixed = TRUE),
  grepl("run_h01_response_family_bootstrap_production.R", qmd, fixed = TRUE),
  grepl("run_h01_mder_METRIC010_bootstrap_production.R", qmd, fixed = TRUE),
  grepl("integrate_h01_mder_METRIC010_production.R", qmd, fixed = TRUE),
  grepl("install_h01_mder_METRIC010_production.R", qmd, fixed = TRUE),
  grepl("MDER production provenance", qmd, fixed = TRUE),
  grepl("mean of viable one-minute", qmd, fixed = TRUE),
  !grepl("mder_ratio_of_integrals", qmd, fixed = TRUE),
  grepl(result_link, qmd, fixed = TRUE),
  grepl(result_anchor_link, qmd, fixed = TRUE),
  grepl(companion_link, result_qmd, fixed = TRUE),
  grepl("## About this analysis record", qmd, fixed = TRUE),
  grepl("## Render boundary", qmd, fixed = TRUE),
  grepl("A **model frame** is the exact set of rows and variables", qmd, fixed = TRUE),
  grepl("lightbox: true", qmd, fixed = TRUE),
  !grepl("source_dir <-", qmd, fixed = TRUE),
  !grepl("dir.create(source_dir", qmd, fixed = TRUE),
  grepl("Calculated on render", qmd, fixed = TRUE),
  grepl("Why it is needed", qmd, fixed = TRUE),
  grepl("Reported scale", qmd, fixed = TRUE),
  grepl("Question answered", qmd, fixed = TRUE),
  grepl("Interpretive limit", qmd, fixed = TRUE),
  grepl("Held constant", qmd, fixed = TRUE),
  grepl("Runs when page renders", qmd, fixed = TRUE),
  grepl("Stored joint-refit support", qmd, fixed = TRUE),
  grepl('PASS = "Verified"', qmd, fixed = TRUE),
  grepl('CHECK = "Review needed"', qmd, fixed = TRUE),
  grepl(
    'if_else(all(.data$status == "PASS"), "Verified", "Review needed")',
    qmd,
    fixed = TRUE
  ),
  grepl("Participant-deletion influence", qmd, fixed = TRUE),
  grepl("Leave-one-site-out latitude analysis", qmd, fixed = TRUE),
  grepl("within-metric FDR adjustment", qmd, fixed = TRUE),
  grepl(
    paste0(
      "Marginal R², conditional R², participant-associated share, and ",
      "model-specific term part-R² values that may overlap and must not be summed"
    ),
    qmd,
    fixed = TRUE
  ),
  grepl("two verified analysis datasets", qmd, fixed = TRUE),
  grepl(
    "one declared model[[:space:]]+implementation for 17 responses",
    qmd,
    perl = TRUE
  ),
  !grepl("alternative preparation", qmd, ignore.case = TRUE),
  !grepl("manuscript-prepared", qmd, ignore.case = TRUE),
  !grepl("H01_postbootstrap_response_family_gate_evidence.csv", qmd, fixed = TRUE),
  !grepl("\\]\\([^)]*[.]html(?:#|\\))", qmd, perl = TRUE),
  !grepl("file://", qmd, fixed = TRUE),
  !grepl("/Users/", qmd, fixed = TRUE),
  !grepl("\\]\\(/", qmd, perl = TRUE)
)

profile_lines <- readLines(paths$quarto_profile, warn = FALSE, encoding = "UTF-8")
assert_adjacent_profile_entries(
  profile_lines,
  "notebooks/hypotheses/H01.qmd",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd"
)

source_files <- file.path(
  root,
  "artifacts/11_source_data/H01/preparation",
  c(
    "H01_preparation_fitted_sample_support.csv",
    "H01_preparation_model_frame_retention.csv"
  )
)
stopifnot(all(file.exists(source_files)))

sample_source <- readr::read_csv(
  source_files[[1L]],
  show_col_types = FALSE,
  progress = FALSE
)
retention_source <- readr::read_csv(
  source_files[[2L]],
  show_col_types = FALSE,
  progress = FALSE
)
stopifnot(
  nrow(sample_source) == 34L,
  nrow(retention_source) == 34L,
  identical(sort(unique(sample_source$placement)), c("Chest", "Near eye")),
  all(sample_source$participants > 0L),
  all(sample_source$participant_days > 0L),
  all(sample_source$observations > 0L),
  all(retention_source$retention > 0 & retention_source$retention <= 1)
)

manifest <- readr::read_csv(
  paths$manifest,
  show_col_types = FALSE,
  progress = FALSE
)
stopifnot(
  nrow(manifest) >= 35L,
  !anyDuplicated(manifest$path),
  all(nchar(manifest$sha256) == 64L),
  all(c(
    "artifacts/11_source_data/H01/preparation/H01_preparation_fitted_sample_support.csv",
    "artifacts/11_source_data/H01/preparation/H01_preparation_model_frame_retention.csv"
  ) %in% manifest$path),
  sum(startsWith(
    manifest$path,
    paste0(
      "_build/nathealth/audit/hypotheses/H01/",
      "H01_analysis_preparation_files/"
    )
  )) >= 2L
)

manifest_files <- file.path(root, manifest$path)
stopifnot(all(file.exists(manifest_files)))
observed_sha256 <- unname(vapply(
  manifest_files,
  artifact_sha256,
  character(1)
))
observed_bytes <- as.numeric(file.info(manifest_files)$size)
mismatch <- manifest$path[
  observed_sha256 != manifest$sha256 |
    observed_bytes != manifest$bytes
]

current_source_dependencies <- c(
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "notebooks/hypotheses/H01.qmd",
  "artifacts/12_manifests/H01_reporting_artifacts.csv",
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
)
for (dependency in current_source_dependencies) {
  row <- manifest[manifest$path == dependency, , drop = FALSE]
  stopifnot(
    nrow(row) == 1L,
    identical(row$sha256, artifact_sha256(file.path(root, dependency))),
    identical(row$bytes, as.numeric(file.info(file.path(root, dependency))$size))
  )
}

if (source_only) {
  allowed_source_only_mismatches <- c(
    "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
    "_build/nathealth/notebooks/hypotheses/H01.html",
    "_quarto-nathealth.yml"
  )
  stopifnot(setequal(mismatch, allowed_source_only_mismatches))
  message(
    "H01 preparation source-only report passed: ",
    length(figure_labels),
    " figure endpoints, ",
    length(table_labels),
    " gt-table endpoints, and current source dependencies verified"
  )
  quit(save = "no", status = 0L)
}

render_required <- c(paths$html, paths$rendered_qmd, paths$result_html)
stopifnot(
  all(file.exists(render_required)),
  identical(read_file_bytes(paths$qmd), read_file_bytes(paths$rendered_qmd)),
  length(mismatch) == 0L
)

document <- xml2::read_html(paths$html)
main <- xml2::xml_find_first(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)
stopifnot(
  grepl("H01 analysis preparation and provenance", main_text, fixed = TRUE),
  grepl("17-response package", main_text, fixed = TRUE),
  grepl("gap-timing-unaware dataset", main_text, fixed = TRUE),
  grepl("At least 1,000 successful joint refits", main_text, fixed = TRUE),
  grepl("MDER production provenance", main_text, fixed = TRUE),
  grepl("mean of viable one-minute", main_text, fixed = TRUE),
  grepl("816", main_text, fixed = TRUE),
  grepl("902", main_text, fixed = TRUE),
  !grepl("alternative preparation", main_text, ignore.case = TRUE),
  !grepl("Execution halted", main_text, fixed = TRUE)
)

expected_figures <- c(
  "fig-h01-prep-sample-support",
  "fig-h01-prep-model-frame-retention"
)
for (id in expected_figures) {
  node <- xml2::xml_find_first(main, paste0(".//*[@id='", id, "']"))
  stopifnot(!inherits(node, "xml_missing"))
}

gt_tables <- xml2::xml_find_all(
  main,
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
figures <- xml2::xml_find_all(main, ".//figure")
images <- xml2::xml_find_all(main, ".//figure//img")
stopifnot(
  length(gt_tables) >= 20L,
  length(figures) >= 2L,
  all(nzchar(xml2::xml_attr(images, "alt")))
)

result_href <- "../../../notebooks/hypotheses/H01.html"
result_anchor_href <- paste0(result_href, "#h01-preregistration-deviations")
stopifnot(
  length(xml2::xml_find_all(
    main,
    paste0(".//a[contains(@href, '", result_href, "')]")
  )) >= 1L,
  length(xml2::xml_find_all(
    main,
    paste0(".//a[@href='", result_anchor_href, "']")
  )) == 1L
)

result_document <- xml2::read_html(paths$result_html)
result_main <- xml2::xml_find_first(
  result_document,
  "//main[@id='quarto-document-content']"
)
prep_href <- paste0(
  "../../audit/hypotheses/H01/H01_analysis_preparation.html"
)
stopifnot(length(xml2::xml_find_all(
  result_main,
  paste0(".//a[contains(@href, '", prep_href, "')]")
)) >= 1L)

source_links <- xml2::xml_find_all(
  main,
  paste0(
    ".//a[contains(@href, ",
    "'H01_analysis_preparation_files/source-data/')]"
  )
)
stopifnot(length(source_links) == 2L)
download_files <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H01",
  xml2::xml_attr(source_links, "href")
)
stopifnot(
  all(file.exists(download_files)),
  identical(
    sort(unname(vapply(source_files, artifact_sha256, character(1)))),
    sort(unname(vapply(download_files, artifact_sha256, character(1))))
  )
)

message(
  "H01 preparation report passed: ",
  length(figures),
  " figures, ",
  length(gt_tables),
  " gt tables, ",
  nrow(manifest),
  " manifest identities"
)
