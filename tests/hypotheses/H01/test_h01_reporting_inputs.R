# Verify H01 reporting inputs, display contracts, and rendered HTML structure.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

table_root <- file.path(root, "artifacts/09_tables/H01/reporting")
source_root <- file.path(root, "artifacts/11_source_data/H01/reporting")
figure_root <- file.path(root, "artifacts/10_figures/H01/reporting")
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_reporting_artifacts.csv"
)
stage3_table_root <- file.path(root, "artifacts/09_tables/H01/stage3")
stage3_source_root <- file.path(root, "artifacts/11_source_data/H01/stage3")
stage3_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
)
html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H01.html"
)

paths <- c(
  model_overview = file.path(
    table_root,
    "H01_reporting_model_overview.csv"
  ),
  site_followups = file.path(
    table_root,
    "H01_reporting_site_followups.csv"
  ),
  exact_samples = file.path(
    table_root,
    "H01_reporting_exact_samples.csv"
  ),
  r2_long = file.path(
    table_root,
    "H01_reporting_r2_preview_long.csv"
  ),
  r2_wide = file.path(
    table_root,
    "H01_reporting_r2_preview_wide.csv"
  ),
  submitted_s2 = file.path(
    table_root,
    "H01_submitted_table_s2_exact_render.csv"
  ),
  submitted_s3 = file.path(
    table_root,
    "H01_submitted_table_s3_exact_render.csv"
  ),
  v0_new_tests = file.path(
    table_root,
    "H01_reporting_v0_new_tests.csv"
  ),
  claim_summary = file.path(
    table_root,
    "H01_reporting_claim_summary.csv"
  ),
  pilot_summary = file.path(
    table_root,
    "H01_reporting_pilot_summary.csv"
  ),
  observed_source = file.path(
    source_root,
    "H01_figure_s10_observed_photoperiod_source.csv"
  ),
  bounds_source = file.path(
    source_root,
    "H01_figure_s10_theoretical_bounds_source.csv"
  ),
  figure_png = file.path(
    figure_root,
    "H01_figure_s10_photoperiod_latitude.png"
  ),
  figure_svg = file.path(
    figure_root,
    "H01_figure_s10_photoperiod_latitude.svg"
  ),
  stage3_publication_summary = file.path(
    stage3_table_root,
    "H01_stage3_primary_publication_summary.csv"
  ),
  stage3_diagnostic_details = file.path(
    stage3_table_root,
    "H01_stage3_diagnostic_details.csv"
  ),
  stage3_figure_display_registry = file.path(
    stage3_table_root,
    "H01_stage3_figure_display_registry.csv"
  ),
  stage3_site_contrasts = file.path(
    stage3_table_root,
    "H01_stage3_site_contrasts.csv"
  ),
  stage3_site_contrast_source = file.path(
    stage3_source_root,
    "H01_stage3_site_contrast_figure_source.csv"
  ),
  exact_samples_by_site = file.path(
    root,
    "artifacts/09_tables/H01/H01_exact_samples_by_site.csv"
  ),
  stage3_manifest = stage3_manifest_path,
  manifest = manifest_path,
  qmd = file.path(root, "notebooks/hypotheses/H01.qmd")
)
stopifnot(all(file.exists(paths)))

read_path <- function(name) {
  readr::read_csv(paths[[name]], show_col_types = FALSE, progress = FALSE)
}

overview <- read_path("model_overview")
followups <- read_path("site_followups")
samples <- read_path("exact_samples")
r2_long <- read_path("r2_long")
r2_wide <- read_path("r2_wide")
submitted_s2 <- read_path("submitted_s2")
submitted_s3 <- read_path("submitted_s3")
v0_new_tests <- read_path("v0_new_tests")
claim_summary <- read_path("claim_summary")
pilot_summary <- read_path("pilot_summary")
observed_source <- read_path("observed_source")
bounds_source <- read_path("bounds_source")
manifest <- read_path("manifest")
stage3_publication_summary <- read_path("stage3_publication_summary")
stage3_diagnostic_details <- read_path("stage3_diagnostic_details")
stage3_figure_display_registry <- read_path("stage3_figure_display_registry")
stage3_site_contrasts <- read_path("stage3_site_contrasts")
stage3_site_contrast_source <- read_path("stage3_site_contrast_source")
exact_samples_by_site <- read_path("exact_samples_by_site")
stage3_manifest <- read_path("stage3_manifest")

stopifnot(
  nrow(overview) == 17L,
  identical(overview$metric_order, as.numeric(seq_len(17L))),
  all(stats::complete.cases(overview[c(
    "site_p_raw",
    "site_p_adjusted",
    "photoperiod_p_raw",
    "photoperiod_p_adjusted",
    "latitude_p_raw",
    "latitude_p_adjusted",
    "adequacy_p_raw",
    "adequacy_p_adjusted"
  )])),
  all(overview$participants > 0L),
  all(overview$observations > 0L),
  all(overview$derivation_support_status %in% c("available", "unavailable")),
  setequal(
    overview$metric_id[overview$derivation_support_status == "unavailable"],
    c("m10_mean_medi", "l10_mean_medi", "m10_midpoint", "l10_midpoint")
  )
)

site_registry <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::arrange(.data$display_order)
stopifnot(
  nrow(followups) == 72L,
  dplyr::n_distinct(followups$metric_id) == 8L,
  all(followups$overall_site_p_adjusted < 0.05),
  all(is.finite(followups$p_raw)),
  all(is.finite(followups$p_adjusted_within_metric)),
  all(followups$contrast_family_n == 9L)
)
followup_site_order <- followups |>
  dplyr::group_by(.data$metric_id) |>
  dplyr::summarise(
    site_order = paste(.data$site, collapse = ";"),
    display_order = paste(.data$site_display_name, collapse = ";"),
    .groups = "drop"
  )
stopifnot(
  all(
    followup_site_order$site_order ==
      paste(site_registry$site, collapse = ";")
  ),
  all(
    followup_site_order$display_order ==
      paste(site_registry$display_name, collapse = ";")
  )
)

stopifnot(
  nrow(samples) == 34L,
  all(samples$sample_status == "FITTED"),
  all(
    samples$derivation_support_status[
      samples$data_scenario_id == "main"
    ] %in% c("available", "unavailable")
  ),
  all(is.finite(samples$derivation_support_hours[
    samples$data_scenario_id == "main" &
      samples$derivation_support_status == "available"
  ])),
  setequal(
    samples$metric_id[
      samples$data_scenario_id == "main" &
        samples$derivation_support_status == "unavailable"
    ],
    c("m10_mean_medi", "l10_mean_medi", "m10_midpoint", "l10_midpoint")
  ),
  all(
    samples$derivation_support_status[
      samples$data_scenario_id == "manuscript_prepared_data"
    ] == "unavailable"
  ),
  all(is.na(samples$derivation_support_hours[
    samples$data_scenario_id == "manuscript_prepared_data"
  ]))
)

stopifnot(
  nrow(r2_long) == 136L,
  dplyr::n_distinct(r2_long$metric_id) == 17L,
  nrow(r2_wide) == 18L,
  all(r2_long$status %in% c("PASS", "NON_ESTIMABLE")),
  all(
    r2_long$status == "PASS" |
      (
        r2_long$measure == "participant_associated_share" &
          r2_long$analysis_unit == "participant" &
          is.na(r2_long$estimate)
      )
  )
)
changed_metric <- r2_long$metric_id == "duration_below_10_pre_sleep"
stopifnot(
  !any(r2_long$preview_only),
  all(r2_long$bootstrap_successful_used[changed_metric] >= 1000L),
  all(r2_long$bootstrap_successful_used[!changed_metric] >= 1000L),
  !any(grepl("PILOT", r2_long$evidence_status, fixed = TRUE))
)

stopifnot(
  nrow(submitted_s2) == 17L,
  nrow(submitted_s3) == 18L,
  setequal(submitted_s2$metric_id, overview$metric_id),
  setequal(
    submitted_s3$metric_id,
    c("grand_average", overview$metric_id)
  ),
  nrow(v0_new_tests) == 51L,
  nrow(claim_summary) == 3L,
  all(claim_summary$question %in% c("site", "photoperiod", "latitude"))
)

stopifnot(
  nrow(pilot_summary) == 1L,
  pilot_summary$targets == 8L,
  pilot_summary$minimum_successful_per_target == 50L,
  pilot_summary$failed_refits == 0L,
  pilot_summary$warning_refits == 0L,
  pilot_summary$all_status_pass
)

stopifnot(
  nrow(observed_source) == 816L,
  dplyr::n_distinct(observed_source$site) == 9L,
  all(unique(observed_source$site) == site_registry$site),
  all(
    observed_source$color_hex ==
      site_registry$color_hex[match(observed_source$site, site_registry$site)]
  ),
  nrow(bounds_source) == 61L,
  identical(
    bounds_source$absolute_latitude_deg,
    as.numeric(0:60)
  ),
  all(
    bounds_source$minimum_possible_photoperiod_hours <=
      bounds_source$maximum_possible_photoperiod_hours
  )
)

stopifnot(
  nrow(stage3_publication_summary) == 17L,
  identical(
    stage3_publication_summary$metric_order,
    as.numeric(seq_len(17L))
  ),
  all(stats::complete.cases(stage3_publication_summary[c(
    "site_p_adjusted",
    "photoperiod_estimate_practical",
    "photoperiod_conf_low_practical",
    "photoperiod_conf_high_practical",
    "photoperiod_p_adjusted",
    "latitude_estimate_practical",
    "latitude_conf_low_practical",
    "latitude_conf_high_practical",
    "latitude_p_adjusted",
    "adequacy_p_adjusted",
    "participants",
    "participant_days",
    "observations",
    "sites"
  )])),
  all(stage3_publication_summary$sites == 9L),
  all(
    stage3_publication_summary$participant_days[
      stage3_publication_summary$metric_order > 2L
    ] ==
      stage3_publication_summary$observations[
        stage3_publication_summary$metric_order > 2L
      ]
  ),
  all(
    stage3_publication_summary$observations[
      stage3_publication_summary$metric_order <= 2L
    ] ==
      stage3_publication_summary$participants[
        stage3_publication_summary$metric_order <= 2L
      ]
  ),
  nrow(stage3_diagnostic_details) == 34L,
  all(stage3_diagnostic_details$assessment %in% c(
    "Acceptable", "Acceptable with limitations"
  )),
  nrow(stage3_figure_display_registry) == 12L,
  setequal(
    stage3_figure_display_registry$figure_id[
      stage3_figure_display_registry$reader_display_status ==
        "retained_not_displayed"
    ],
    c(
      "photoperiod_latitude_near_eye",
      "photoperiod_latitude_chest"
    )
  ),
  all(file.exists(file.path(
    root,
    stage3_figure_display_registry$artifact_path
  )))
)

site_sample_check <- stage3_site_contrasts |>
  dplyr::left_join(
    exact_samples_by_site |>
      dplyr::transmute(
        .data$run_id,
        .data$metric_order,
        .data$metric_id,
        .data$site,
        expected_site_observations = as.integer(.data$observations)
      ),
    by = c("run_id", "metric_order", "metric_id", "site"),
    relationship = "one-to-one"
  )
stopifnot(
  identical(
    artifact_sha256(paths[["stage3_site_contrasts"]]),
    artifact_sha256(paths[["stage3_site_contrast_source"]])
  ),
  all(c(
    "site_participants", "site_participant_days", "site_observations",
    "support_display", "site_panel_key", "site_axis_label", "scale_group",
    "figure_panel_tag", "figure_panel_label", "metric_facet_label",
    "display_half_range", "display_x_min", "display_x_max"
  ) %in% names(stage3_site_contrasts)),
  all(site_sample_check$site_observations ==
    site_sample_check$expected_site_observations),
  all(grepl(", n=[0-9]+\\)$", stage3_site_contrasts$site_axis_label)),
  setequal(
    unique(stage3_site_contrasts$figure_panel_tag[
      stage3_site_contrasts$run_id == "main__glasses__all_available"
    ]),
    c("A", "B")
  ),
  setequal(
    unique(stage3_site_contrasts$figure_panel_tag[
      stage3_site_contrasts$run_id == "main__chest__all_available"
    ]),
    c("A", "B")
  ),
  all(
    stage3_site_contrasts$figure_panel_tag ==
      ifelse(stage3_site_contrasts$effect_type == "ratio", "A", "B")
  ),
  all(
    stage3_site_contrasts$scale_group ==
      ifelse(stage3_site_contrasts$effect_type == "ratio", "Ratios", "Differences")
  ),
  all(abs(
    (stage3_site_contrasts$null_value - stage3_site_contrasts$display_x_min) -
      (stage3_site_contrasts$display_x_max - stage3_site_contrasts$null_value)
  ) < 1e-12),
  all(stage3_site_contrasts$display_x_min <=
    stage3_site_contrasts$conf_low_practical),
  all(stage3_site_contrasts$display_x_max >=
    stage3_site_contrasts$conf_high_practical),
  all(
    stage3_site_contrasts$support_display ==
      ifelse(
        stage3_site_contrasts$supported_within_metric,
        "Adjusted p < 0.050",
        "Adjusted p ≥ 0.050"
      )
  )
)

for (index in seq_len(nrow(manifest))) {
  manifest_file <- file.path(root, manifest$path[[index]])
  stopifnot(
    file.exists(manifest_file),
    identical(artifact_sha256(manifest_file), manifest$sha256[[index]])
  )
}

for (index in seq_len(nrow(stage3_manifest))) {
  manifest_file <- file.path(root, stage3_manifest$path[[index]])
  stopifnot(
    file.exists(manifest_file),
    identical(
      artifact_sha256(manifest_file),
      stage3_manifest$sha256[[index]]
    )
  )
}

qmd_text <- paste(readLines(paths[["qmd"]], warn = FALSE), collapse = "\n")
stopifnot(
  grepl("library\\(gt\\)", qmd_text),
  !grepl("knitr::kable", qmd_text, fixed = TRUE),
  grepl('subtitle: "Standalone results report"', qmd_text, fixed = TRUE),
  grepl(
    "1,000 successful joint bootstrap refits",
    qmd_text,
    fixed = TRUE
  ),
  grepl(
    '::: {.callout-note title="Answer in brief"}',
    qmd_text,
    fixed = TRUE
  ),
  !grepl("## Results in brief", qmd_text, fixed = TRUE),
  !grepl("## Photoperiod and latitude coverage", qmd_text, fixed = TRUE),
  !grepl("#fig-h01-photoperiod-near-eye", qmd_text, fixed = TRUE),
  !grepl("#fig-h01-photoperiod-chest", qmd_text, fixed = TRUE),
  grepl("tbl-h01-primary-publication-summary", qmd_text, fixed = TRUE),
  grepl("<sub>participants</sub>", qmd_text, fixed = TRUE),
  grepl("<sub>participant-days</sub>", qmd_text, fixed = TRUE),
  grepl("All models include nine sites", qmd_text, fixed = TRUE),
  grepl("Filled circles with thicker", qmd_text, fixed = TRUE),
  grepl("Panel A contains ratios", qmd_text, fixed = TRUE),
  grepl("panel B contains differences", qmd_text, fixed = TRUE),
  !grepl("facet tags A–H", qmd_text, fixed = TRUE),
  !grepl("facet tags A–M", qmd_text, fixed = TRUE),
  grepl("tbl-h01-primary-site-deviation-matrix", qmd_text, fixed = TRUE),
  length(gregexpr("tbl-h01-samples-", qmd_text, fixed = TRUE)[[1]]) == 8L,
  grepl("tbl-h01-representative-diagnostics", qmd_text, fixed = TRUE),
  grepl("fig-h01-diagnostic-mean-mel-edi", qmd_text, fixed = TRUE),
  grepl("fig-h01-diagnostic-pre-sleep", qmd_text, fixed = TRUE),
  grepl("fig-h01-diagnostic-wake-250", qmd_text, fixed = TRUE),
  grepl("fig-h01-diagnostic-sleep-below-1", qmd_text, fixed = TRUE),
  grepl("tbl-h01-participant-formulas", qmd_text, fixed = TRUE),
  grepl("tbl-h01-participant-day-formulas", qmd_text, fixed = TRUE),
  grepl("tbl-h01-preregistered-scope-formulas", qmd_text, fixed = TRUE),
  grepl("formula_display", qmd_text, fixed = TRUE),
  !grepl("PILOT", qmd_text, fixed = TRUE),
  !grepl("INFERENCE OR MANUSCRIPT REPORTING", qmd_text, fixed = TRUE),
  any(grepl(
    "config/site_display_registry.csv",
    readLines(
      file.path(root, "scripts/hypotheses/H01/build_h01_reporting_inputs.R"),
      warn = FALSE
    ),
    fixed = TRUE
  )),
  any(grepl(
    "config/site_display_registry.csv",
    readLines(
      file.path(
        root,
        "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R"
      ),
      warn = FALSE
    ),
    fixed = TRUE
  )),
  file.exists(file.path(root, "audit/decisions/answer_in_brief_callout.md"))
)

if (file.exists(html_path)) {
  html <- rvest::read_html(html_path)
  gt_tables <- rvest::html_elements(html, "table.gt_table")
  images <- rvest::html_elements(html, "img")
  image_sources <- rvest::html_attr(images, "src")
  image_alt <- rvest::html_attr(images, "alt")
  resolved_images <- normalizePath(
    file.path(dirname(html_path), image_sources),
    mustWork = FALSE
  )
  page_text <- rvest::html_text2(rvest::html_element(html, "body"))
  callout_titles <- rvest::html_attr(
    rvest::html_elements(html, ".callout-note"),
    "title"
  )
  site_matrix <- rvest::html_element(
    html,
    "#tbl-h01-primary-site-deviation-matrix table.gt_table"
  )
  site_matrix_headers <- rvest::html_text2(rvest::html_elements(
    site_matrix,
    "thead tr:last-child th"
  ))
  publication_table <- rvest::html_element(
    html,
    "#tbl-h01-primary-publication-summary"
  )
  publication_table_text <- rvest::html_text2(publication_table)
  publication_subscripts <- rvest::html_text2(rvest::html_elements(
    publication_table,
    "tbody td sub"
  ))
  publication_sample_n <- rvest::html_elements(
    publication_table,
    "tbody td em"
  )
  stopifnot(
    length(gt_tables) == 36L,
    length(rvest::html_elements(html, "table.gt_table thead")) == 36L,
    length(rvest::html_elements(html, "table.gt_table tbody")) == 36L,
    length(images) == 10L,
    all(!is.na(image_alt) & nzchar(image_alt)),
    all(!grepl("Users/zauner", image_sources, fixed = TRUE)),
    all(file.exists(resolved_images)),
    length(rvest::html_elements(html, ".cell-output-error")) == 0L,
    length(rvest::html_elements(html, ".callout-note")) == 1L,
    identical(callout_titles, "Answer in brief"),
    length(rvest::html_elements(html, ".panel-tabset")) == 2L,
    length(rvest::html_elements(
      html,
      "#tbl-h01-primary-publication-summary table.gt_table"
    )) == 1L,
    length(publication_sample_n) == 34L,
    sum(publication_subscripts == "participants") == 17L,
    sum(publication_subscripts == "participant-days") == 17L,
    grepl("participants = 141", publication_table_text, fixed = TRUE),
    grepl("participant-days = 816", publication_table_text, fixed = TRUE),
    grepl("All models include nine sites", publication_table_text, fixed = TRUE),
    length(rvest::html_elements(
      html,
      "#tbl-h01-primary-site-deviation-matrix table.gt_table"
    )) == 1L,
    length(rvest::html_elements(site_matrix, "tbody tr")) == 8L,
    identical(
      site_matrix_headers,
      c(
        "Borås (SE)", "Delft (NL)", "Dortmund (DE)",
        "Tübingen (DE)", "Munich (DE)", "Madrid (ES)",
        "Izmir (TR)", "San José (CR)", "Kumasi (GH)"
      )
    ),
    length(rvest::html_elements(site_matrix, "tbody td strong")) == 17L,
    sum(grepl(
      "H01_stage3_paired_placement",
      image_sources,
      fixed = TRUE
    )) == 1L,
    sum(grepl("_diagnostics.png", image_sources, fixed = TRUE)) == 4L,
    !any(grepl(
      "H01_stage3_photoperiod_latitude",
      image_sources,
      fixed = TRUE
    )),
    grepl("Standalone results report", page_text, fixed = TRUE),
    grepl("Answer in brief", page_text, fixed = TRUE),
    !grepl("Results in brief", page_text, fixed = TRUE),
    !grepl("Photoperiod and latitude coverage", page_text, fixed = TRUE),
    !grepl("<environment:", page_text, fixed = TRUE),
    !grepl("PILOT — NOT FOR", page_text, fixed = TRUE),
    !grepl("V0", page_text, fixed = TRUE),
    !grepl("manuscript-prepared", page_text, fixed = TRUE),
    !grepl("submitted-versus", page_text, fixed = TRUE)
  )
}

message("H01 reporting input and HTML structure tests passed")
