# Focused scientific and structural checks for the standalone H03 report.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H03 reader-report tests require R 4.6.1", call. = FALSE)
}
source(file.path(root, "scripts/pipeline/paths_io.R"))

qmd_path <- file.path(root, "notebooks/hypotheses/H03.qmd")
html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H03.html"
)
artifact <- function(...) file.path(root, "artifacts", ...)

figure_names <- c(
  "H03_reader_heterogeneity_category_estimates.png",
  "H03_near_eye_site_context_estimates.png",
  "H03_primary_residual_diagnostics.png",
  "H03_paired_placement_comparison.png",
  "H03_reader_temporal_near_eye.png",
  "H03_reader_temporal_chest.png",
  "H03_reader_temporal_diagnostics.png",
  "H03_reader_latitude_category_slopes.png"
)

source_names <- c(
  "H03_reader_heterogeneity_category_figure_data.csv",
  "H03_reader_temporal_near_eye_curves.csv",
  "H03_reader_temporal_near_eye_ratios.csv",
  "H03_reader_temporal_near_eye_support.csv",
  "H03_reader_temporal_chest_curves.csv",
  "H03_reader_temporal_chest_ratios.csv",
  "H03_reader_temporal_chest_support.csv",
  "H03_reader_temporal_residual_points.csv",
  "H03_reader_temporal_residual_bins.csv",
  "H03_reader_temporal_zero_calibration.csv",
  "H03_reader_latitude_site_support.csv",
  "H03_reader_latitude_figure_data.csv"
)

required_files <- c(
  qmd_path,
  html_path,
  artifact("06_model_data", "H03", "H03_model_frame_index.csv"),
  artifact("09_tables", "H03", "H03_primary_category_estimands.csv"),
  artifact("09_tables", "H03", "H03_reader_heterogeneity_category_estimands.csv"),
  artifact("09_tables", "H03", "H03_primary_omnibus_tests.csv"),
  artifact("09_tables", "H03", "H03_site_context_estimands.csv"),
  artifact("09_tables", "H03", "H03_glm_r_squared_and_effect_partition.csv"),
  artifact("09_tables", "H03", "H03_sensitivity_comparison.csv"),
  artifact("09_tables", "H03", "H03_reader_temporal_model_summary.csv"),
  artifact("09_tables", "H03", "H03_reader_temporal_weighted_r_squared.csv"),
  artifact("09_tables", "H03", "H03_reader_temporal_variance_allocation.csv"),
  artifact("09_tables", "H03", "H03_reader_latitude_category_slopes.csv"),
  artifact("08_diagnostics", "H03", "H03_reader_temporal_k_check.csv"),
  artifact("08_diagnostics", "H03", "H03_reader_temporal_residual_acf.csv"),
  artifact("08_diagnostics", "H03", "H03_reader_latitude_model_diagnostics.csv"),
  artifact("08_diagnostics", "H03", "H03_reader_latitude_leave_one_site_out.csv"),
  artifact("12_manifests", "H03", "H03_stage3_reader_asset_manifest.csv"),
  artifact("12_manifests", "H03", "H03_stage3_figure_readability_qa.csv"),
  artifact("12_manifests", "H03", "H03_stage3_revision_asset_manifest.csv"),
  artifact("12_manifests", "H03", "H03_stage3_revision_figure_readability_qa.csv"),
  artifact("12_manifests", "H03", "H03_stage3_artifacts.csv"),
  file.path(artifact("10_figures", "H03"), figure_names),
  file.path(artifact("11_source_data", "H03"), source_names)
)
stopifnot(all(file.exists(required_files)))

samples <- readr::read_csv(
  artifact("06_model_data", "H03", "H03_model_frame_index.csv"),
  show_col_types = FALSE
) |>
  filter(.data$run_id %in% c("main__near_eye", "main__chest")) |>
  arrange(match(.data$run_id, c("main__near_eye", "main__chest")))
primary <- readr::read_csv(
  artifact("09_tables", "H03", "H03_primary_category_estimands.csv"),
  show_col_types = FALSE
)
interaction_category <- readr::read_csv(
  artifact(
    "09_tables", "H03", "H03_reader_heterogeneity_category_estimands.csv"
  ),
  show_col_types = FALSE
)
omnibus <- readr::read_csv(
  artifact("09_tables", "H03", "H03_primary_omnibus_tests.csv"),
  show_col_types = FALSE
)
temporal <- readr::read_csv(
  artifact("09_tables", "H03", "H03_reader_temporal_model_summary.csv"),
  show_col_types = FALSE
) |>
  arrange(match(.data$placement, c("Near-eye", "Chest")))
temporal_r2 <- readr::read_csv(
  artifact("09_tables", "H03", "H03_reader_temporal_weighted_r_squared.csv"),
  show_col_types = FALSE
) |>
  arrange(match(.data$placement, c("Near-eye", "Chest")))
allocation <- readr::read_csv(
  artifact("09_tables", "H03", "H03_reader_temporal_variance_allocation.csv"),
  show_col_types = FALSE
)
latitude_slopes <- readr::read_csv(
  artifact("09_tables", "H03", "H03_reader_latitude_category_slopes.csv"),
  show_col_types = FALSE
)
latitude_diagnostics <- readr::read_csv(
  artifact("08_diagnostics", "H03", "H03_reader_latitude_model_diagnostics.csv"),
  show_col_types = FALSE
)
figure_qa <- dplyr::bind_rows(
  readr::read_csv(
    artifact("12_manifests", "H03", "H03_stage3_figure_readability_qa.csv"),
    show_col_types = FALSE
  ),
  readr::read_csv(
    artifact(
      "12_manifests", "H03", "H03_stage3_revision_figure_readability_qa.csv"
    ),
    show_col_types = FALSE
  )
)

stopifnot(
  identical(as.integer(samples$observations), c(17935L, 19512L)),
  identical(as.integer(samples$participants), c(140L, 151L)),
  identical(as.integer(samples$participant_days), c(801L, 880L)),
  identical(as.integer(samples$sites), c(9L, 8L)),
  nrow(primary) == 14L,
  all(table(primary$placement) == 7L),
  all(primary$sites[primary$short_label == "Outdoor electric"] >= 7L),
  nrow(interaction_category) == 14L,
  all(table(interaction_category$placement) == 7L),
  abs(
    interaction_category$expected_mel_edi_lx[
      interaction_category$placement == "Near-eye" &
        interaction_category$short_label == "Indoor electric"
    ] - 85.113996
  ) < 1e-6,
  interaction_category$standardization_status[
    interaction_category$placement == "Chest" &
      interaction_category$short_label == "External light during sleep"
  ] == "CATEGORY_STANDARDIZATION_NON_ESTIMABLE",
  all(omnibus$status == "ESTIMABLE"),
  nrow(temporal) == 2L,
  identical(as.integer(temporal$nthreads), c(1L, 1L)),
  all(temporal$converged),
  all(temporal$final_warning_count == 0L),
  all(temporal$smoothing_hessian_positive_definite),
  all(temporal$no_simulation),
  all(abs(temporal$standardized_residual_lag1 - c(0.1458163, 0.1438087)) < 1e-6),
  all(abs(temporal_r2$r_squared - c(0.5444160, 0.4989811)) < 1e-6),
  nrow(allocation) == 10L,
  all(abs(allocation$shapley_efficiency_error) < 1e-10),
  nrow(latitude_slopes) == 14L,
  all(table(latitude_slopes$placement) == 7L),
  all(latitude_diagnostics$converged),
  all(latitude_diagnostics$warning_count == 0L),
  all(latitude_diagnostics$design_rank == 14L),
  abs(
    latitude_slopes$ratio_per_10deg[
      latitude_slopes$placement == "Near-eye" &
        latitude_slopes$short_label == "Indoor electric"
    ] - 1.1969699
  ) < 1e-6,
  all(figure_qa$final_asset_tightly_bounded),
  all(figure_qa$smallest_essential_effective_pt >= 5)
)

reporting_text <- paste(
  readLines(
    file.path(root, "scripts/hypotheses/H03/h03_reporting.R"),
    warn = FALSE
  ),
  collapse = "\n"
)
site_figure_function <- sub(
  "^[\\s\\S]*?h03_site_context_figure <- function",
  "h03_site_context_figure <- function",
  reporting_text,
  perl = TRUE
)
site_figure_function <- sub(
  "h03_paired_placement_figure <- function[\\s\\S]*$",
  "",
  site_figure_function,
  perl = TRUE
)
revision_text <- paste(
  readLines(
    file.path(
      root,
      "scripts/hypotheses/H03/build_h03_stage3_revision.R"
    ),
    warn = FALSE
  ),
  collapse = "\n"
)
stopifnot(
  lengths(regmatches(
    reporting_text,
    gregexpr("size = 2.0", reporting_text, fixed = TRUE)
  )) == 4L,
  grepl("ggplot2::aes(fill = .data$site)", site_figure_function, fixed = TRUE),
  !grepl('colour = "grey15"', site_figure_function, fixed = TRUE),
  !grepl('scales = "free_x"', site_figure_function, fixed = TRUE),
  grepl(
    "ggplot2::aes(fill = .data$category_code)",
    revision_text,
    fixed = TRUE
  ),
  !grepl('"TRUE" = "black"', revision_text, fixed = TRUE)
)

qmd_text <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
required_qmd_formula_fragments <- c(
  "geo_medi_1h ~ site + light_source",
  "geo_medi_1h ~ site * light_source",
  "geo_medi_1h ~ 0 + site_source_cell",
  paste0(
    "geo_medi_1h ~ 0 + light_source + ",
    "light_source:absolute_latitude_10deg_centered"
  )
)
stopifnot(all(vapply(
  required_qmd_formula_fragments,
  grepl,
  logical(1L),
  x = qmd_text,
  fixed = TRUE
)))
temporal_formula_compact <- gsub(
  "[[:space:]]+",
  "",
  temporal$formula[[1L]]
)
required_temporal_formula_fragments <- c(
  's(time_hour,bs="cc",k=12)',
  's(time_hour,light_source,bs="sz",k=12)',
  's(time_hour,site,bs="sz",k=12)',
  's(time_hour,participant,bs="fs",k=10)',
  's(participant_day,bs="re")'
)
stopifnot(all(vapply(
  required_temporal_formula_fragments,
  grepl,
  logical(1L),
  x = temporal_formula_compact,
  fixed = TRUE
)))

doc <- xml2::read_html(html_path)
main <- xml2::xml_find_first(doc, "//main")
html_text <- xml2::xml_text(main)

required_reader_phrases <- c(
  "Answer in brief",
  "F(6, 139) = 97.54",
  "p <0.001",
  "17,935 near-eye participant-hours",
  "19,512 chest participant-hours",
  "site-standardized",
  "85.1 lx",
  "gap-timing-unaware dataset",
  "146 of 149 estimable non-reference category ratios",
  "Exploratory time-of-day context",
  "ratios to the global daily smooth",
  "Site-standardized participant-balanced R²",
  "Exploratory linear latitude replacement",
  "ratio 1.197 per +10°",
  "The result is observational"
)
stopifnot(
  all(vapply(
    required_reader_phrases,
    grepl,
    logical(1L),
    x = html_text,
    fixed = TRUE
  )),
  !grepl("\\bV0\\b", html_text),
  !grepl("Stage [1-4]", html_text),
  !grepl("\\bpilot\\b", html_text, ignore.case = TRUE),
  !grepl("construction history", html_text, ignore.case = TRUE),
  !grepl("\\bbout\\b", html_text, ignore.case = TRUE),
  !grepl("F\\([^)]*\\)\\s*=\\s*,", html_text),
  !grepl("`r\\s", html_text),
  !grepl("@(?:fig|tbl)-", html_text)
)

figures <- xml2::xml_find_all(doc, "//figure//img")
alts <- xml2::xml_attr(figures, "alt")
stopifnot(
  length(figures) == 8L,
  all(!is.na(alts)),
  all(nchar(alts) >= 150L),
  length(xml2::xml_find_all(
    doc,
    "//table[contains(@class, 'gt_table')]"
  )) == 13L
)

local_links <- xml2::xml_attr(
  xml2::xml_find_all(doc, "//a[starts-with(@href, '../../artifacts/') ]"),
  "href"
)
local_sources <- normalizePath(
  file.path(dirname(html_path), local_links),
  winslash = "/",
  mustWork = FALSE
)
stopifnot(
  length(local_links) == 18L,
  all(grepl("\\.csv$", local_links)),
  all(file.exists(local_sources))
)

rendered_figure_paths <- file.path(
  root,
  "_build/nathealth/artifacts/10_figures/H03",
  figure_names
)
stopifnot(all(file.exists(rendered_figure_paths)))

stage3_manifest <- readr::read_csv(
  artifact("12_manifests", "H03", "H03_stage3_artifacts.csv"),
  show_col_types = FALSE
)
expected_manifest_columns <- c(
  "path",
  "artifact_class",
  "artifact_type",
  "sha256",
  "bytes",
  "producer",
  "r_version",
  "written_utc"
)
expected_manifest_paths <- c(
  "notebooks/hypotheses/H03.qmd",
  "_build/nathealth/notebooks/hypotheses/H03.html",
  "scripts/hypotheses/H03/build_h03_stage3_assets.R",
  "scripts/hypotheses/H03/build_h03_stage3_revision.R",
  "scripts/hypotheses/H03/build_h03_stage3_manifest.R",
  "tests/hypotheses/H03/test_h03_stage3_reader_report.R",
  "artifacts/12_manifests/H03/H03_stage3_reader_asset_manifest.csv",
  "artifacts/12_manifests/H03/H03_stage3_figure_readability_qa.csv",
  "artifacts/12_manifests/H03/H03_stage3_revision_asset_manifest.csv",
  "artifacts/12_manifests/H03/H03_stage3_revision_figure_readability_qa.csv",
  "artifacts/10_figures/H03/H03_reader_heterogeneity_category_estimates.png",
  "artifacts/10_figures/H03/H03_reader_temporal_near_eye.png",
  "artifacts/10_figures/H03/H03_reader_temporal_chest.png",
  "artifacts/10_figures/H03/H03_reader_temporal_diagnostics.png",
  "artifacts/10_figures/H03/H03_reader_latitude_category_slopes.png"
)
stopifnot(
  identical(names(stage3_manifest), expected_manifest_columns),
  !anyDuplicated(stage3_manifest$path),
  all(expected_manifest_paths %in% stage3_manifest$path),
  !"artifacts/12_manifests/H03/H03_stage3_artifacts.csv" %in%
    stage3_manifest$path,
  !"artifacts/12_manifests/H03/H03_preparation_report_manifest.csv" %in%
    stage3_manifest$path,
  !"audit/handoffs/H03_worker_handoff.md" %in% stage3_manifest$path,
  all(stage3_manifest$r_version == "4.6.1"),
  all(nchar(stage3_manifest$sha256) == 64L)
)
manifest_absolute_paths <- file.path(root, stage3_manifest$path)
stopifnot(
  all(file.exists(manifest_absolute_paths)),
  identical(
    unname(vapply(manifest_absolute_paths, artifact_sha256, character(1L))),
    stage3_manifest$sha256
  )
)

cat("H03 Stage 3 reader-report checks passed.\n")
