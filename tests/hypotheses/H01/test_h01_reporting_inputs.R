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
  stage3_primary_metric_synthesis = file.path(
    stage3_table_root,
    "H01_stage3_primary_metric_synthesis.csv"
  ),
  stage3_r2_table = file.path(
    stage3_table_root,
    "H01_stage3_r2_table.csv"
  ),
  descriptive_metric_summary = file.path(
    root,
    "artifacts/09_tables/descriptives/metric_descriptive_summary_replica.csv"
  ),
  descriptive_metric_values = file.path(
    root,
    "artifacts/11_source_data/descriptives/metric_plot_values.csv"
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
  stage3_model_support_source = file.path(
    stage3_source_root,
    "H01_stage3_model_support_figure_source.csv"
  ),
  stage3_r2_source = file.path(
    stage3_source_root,
    "H01_stage3_r2_figure_source.csv"
  ),
  stage3_paired_source = file.path(
    stage3_source_root,
    "H01_stage3_paired_placement_figure_source.csv"
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

qmd_display_text <- paste(
  readLines(paths[["qmd"]], warn = FALSE),
  collapse = "\n"
)
fdr_display_mapping <- paste(
  "    Multiplicity = dplyr::recode(",
  "      .data$multiplicity,",
  "      `Primary 17-test BH family` = \"Primary 17-test FDR family\"",
  "    )",
  sep = "\n"
)
count_fixed <- function(pattern, text) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1]]
  if (identical(matches, -1L)) 0L else length(matches)
}
stopifnot(
  count_fixed(fdr_display_mapping, qmd_display_text) == 1L,
  count_fixed("Primary 17-test FDR family", qmd_display_text) == 1L
)

sealed_prerender_html_sha256 <-
  "ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72"
stopifnot(file.exists(html_path))
display_html <- rvest::read_html(html_path)
l10_noon_tables <- rvest::html_elements(
  display_html,
  "#tbl-h01-l10-noon-support table.gt_table"
)
stopifnot(length(l10_noon_tables) == 1L)
l10_noon_cell_text <- rvest::html_text2(rvest::html_elements(
  l10_noon_tables[[1]],
  "tbody td"
))
visible_fdr_cells <- sum(
  l10_noon_cell_text == "Primary 17-test FDR family"
)
visible_bh_cells <- sum(
  l10_noon_cell_text == "Primary 17-test BH family"
)
if (identical(artifact_sha256(html_path), sealed_prerender_html_sha256)) {
  stopifnot(visible_fdr_cells == 0L, visible_bh_cells == 8L)
} else {
  stopifnot(visible_fdr_cells == 8L, visible_bh_cells == 0L)
}

if (identical(Sys.getenv("H01_SOURCE_ONLY_DISPLAY_TEST"), "true")) {
  message(
    "H01 source-only FDR display mapping and sealed-HTML transition test passed"
  )
  quit(save = "no", status = 0L)
}

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
stage3_primary_metric_synthesis <- read_path("stage3_primary_metric_synthesis")
stage3_r2_table <- read_path("stage3_r2_table")
descriptive_metric_summary <- read_path("descriptive_metric_summary")
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
  identical(
    overview$metric_id[overview$metric_order == 17L],
    "mder_mean_of_viable_ratios"
  ),
  identical(
    overview$submitted_metric_id[overview$metric_order == 17L],
    "mder_ratio_of_integrals"
  ),
  all(is.finite(unlist(overview[overview$metric_order == 17L, c(
    "site_p_adjusted_v0", "photoperiod_p_adjusted_v0",
    "latitude_p_adjusted_v0"
  )]))),
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
  nrow(followups) ==
    nrow(site_registry) * sum(overview$site_p_adjusted < 0.05),
  dplyr::n_distinct(followups$metric_id) ==
    sum(overview$site_p_adjusted < 0.05),
  setequal(
    unique(followups$metric_id),
    overview$metric_id[overview$site_p_adjusted < 0.05]
  ),
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

synthesis_descriptive_expected <- descriptive_metric_summary |>
  dplyr::filter(.data$placement == "near_eye", .data$site == "Overall") |>
  dplyr::transmute(
    .data$metric_id,
    expected_description = .data$meaning_and_relevance,
    expected_analysis_unit = .data$analysis_unit,
    expected_unit = .data$unit,
    expected_scaling = .data$scaling,
    expected_median = .data$median,
    expected_q1 = .data$q1,
    expected_q3 = .data$q3,
    expected_median_display = .data$median_formatted,
    expected_q1_display = .data$q1_formatted,
    expected_q3_display = .data$q3_formatted,
    expected_descriptive_participants = as.integer(.data$n_participants),
    expected_descriptive_days = as.integer(.data$n_participant_days),
    expected_descriptive_observations = as.integer(.data$n_observations)
  )
synthesis_descriptive_check <- stage3_primary_metric_synthesis |>
  dplyr::left_join(
    synthesis_descriptive_expected,
    by = "metric_id",
    relationship = "one-to-one"
  )
synthesis_r2_expected <- stage3_r2_table |>
  dplyr::filter(
    .data$run_id == "main__glasses__all_available",
    .data$row_type == "Metric",
    .data$measure %in% c(
      "marginal_r2", "conditional_r2", "participant_associated_share",
      "site_part_r2", "photoperiod_part_r2", "latitude_part_r2"
    )
  ) |>
  dplyr::select(
    "metric_id", "measure", "estimate", "conf_low", "conf_high",
    "bootstrap_successful_used", "term_supported"
  ) |>
  tidyr::pivot_wider(
    names_from = "measure",
    values_from = c(
      "estimate", "conf_low", "conf_high", "bootstrap_successful_used",
      "term_supported"
    ),
    names_glue = "expected_{.value}_{measure}"
  )
synthesis_r2_check <- stage3_primary_metric_synthesis |>
  dplyr::left_join(
    synthesis_r2_expected,
    by = "metric_id",
    relationship = "one-to-one"
  )
synthesis_density_paths <- file.path(
  root,
  stage3_primary_metric_synthesis$density_artifact_path
)
r2_value_fields <- unlist(lapply(
  c(
    "marginal_r2", "conditional_r2", "participant_associated_share",
    "site_part_r2", "photoperiod_part_r2", "latitude_part_r2"
  ),
  function(measure) {
    paste0(
      c("estimate_", "conf_low_", "conf_high_", "bootstrap_successful_used_"),
      measure
    )
  }
))
stopifnot(
  nrow(stage3_primary_metric_synthesis) == 17L,
  identical(
    stage3_primary_metric_synthesis$metric_order,
    as.numeric(seq_len(17L))
  ),
  !anyDuplicated(stage3_primary_metric_synthesis$metric_id),
  !"mder_ratio_of_integrals" %in% stage3_primary_metric_synthesis$metric_id,
  "mder_mean_of_viable_ratios" %in%
    stage3_primary_metric_synthesis$metric_id,
  all(stage3_primary_metric_synthesis$sites == 9L),
  all(
    stage3_primary_metric_synthesis$participants ==
      stage3_publication_summary$participants
  ),
  all(
    stage3_primary_metric_synthesis$participant_days ==
      stage3_publication_summary$participant_days
  ),
  all(
    stage3_primary_metric_synthesis$observations ==
      stage3_publication_summary$observations
  ),
  identical(
    synthesis_descriptive_check$metric_description,
    synthesis_descriptive_check$expected_description
  ),
  identical(
    synthesis_descriptive_check$descriptive_analysis_unit,
    synthesis_descriptive_check$expected_analysis_unit
  ),
  identical(
    synthesis_descriptive_check$descriptive_unit,
    synthesis_descriptive_check$expected_unit
  ),
  identical(
    synthesis_descriptive_check$descriptive_scaling,
    synthesis_descriptive_check$expected_scaling
  ),
  isTRUE(all.equal(
    synthesis_descriptive_check$descriptive_median,
    synthesis_descriptive_check$expected_median,
    tolerance = 0,
    check.attributes = FALSE
  )),
  isTRUE(all.equal(
    synthesis_descriptive_check$descriptive_q1,
    synthesis_descriptive_check$expected_q1,
    tolerance = 0,
    check.attributes = FALSE
  )),
  isTRUE(all.equal(
    synthesis_descriptive_check$descriptive_q3,
    synthesis_descriptive_check$expected_q3,
    tolerance = 0,
    check.attributes = FALSE
  )),
  identical(
    synthesis_descriptive_check$descriptive_median_display,
    synthesis_descriptive_check$expected_median_display
  ),
  identical(
    synthesis_descriptive_check$descriptive_q1_display,
    synthesis_descriptive_check$expected_q1_display
  ),
  identical(
    synthesis_descriptive_check$descriptive_q3_display,
    synthesis_descriptive_check$expected_q3_display
  ),
  all(
    synthesis_descriptive_check$descriptive_participants ==
      synthesis_descriptive_check$expected_descriptive_participants
  ),
  all(
    synthesis_descriptive_check$descriptive_participant_days ==
      synthesis_descriptive_check$expected_descriptive_days
  ),
  all(
    synthesis_descriptive_check$descriptive_observations ==
      synthesis_descriptive_check$expected_descriptive_observations
  ),
  all(vapply(r2_value_fields, function(field) {
    isTRUE(all.equal(
      synthesis_r2_check[[field]],
      synthesis_r2_check[[paste0("expected_", field)]],
      tolerance = 0,
      check.attributes = FALSE
    ))
  }, logical(1))),
  all(file.exists(synthesis_density_paths)),
  all(file.info(synthesis_density_paths)$size > 0L),
  all(grepl(
    "^artifacts/10_figures/H01/stage3/metric_density/",
    stage3_primary_metric_synthesis$density_artifact_path
  )),
  all(
    stage3_primary_metric_synthesis$density_artifact_path %in%
      stage3_manifest$path
  ),
  paths[["descriptive_metric_summary"]] %in%
    file.path(root, stage3_manifest$path),
  paths[["descriptive_metric_values"]] %in%
    file.path(root, stage3_manifest$path)
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
table_labels <- regmatches(
  qmd_text,
  gregexpr("(?<=#\\| label: )tbl-h01-[a-z0-9-]+", qmd_text, perl = TRUE)
)[[1]]
figure_labels <- regmatches(
  qmd_text,
  gregexpr("(?<=#)fig-h01-[a-z0-9-]+", qmd_text, perl = TRUE)
)[[1]]
first_table_position <- regexpr("#| label: tbl-h01-", qmd_text, fixed = TRUE)[[1]]
first_figure_position <- regexpr("#fig-h01-", qmd_text, fixed = TRUE)[[1]]
stopifnot(
  grepl("library\\(gt\\)", qmd_text),
  !grepl("knitr::kable", qmd_text, fixed = TRUE),
  grepl(
    'subtitle: "Site, photoperiod, and latitude associations in personal light exposure"',
    qmd_text,
    fixed = TRUE
  ),
  grepl("lightbox: true", qmd_text, fixed = TRUE),
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
  length(table_labels) == 37L,
  !anyDuplicated(table_labels),
  length(figure_labels) == 10L,
  !anyDuplicated(figure_labels),
  first_table_position == regexpr(
    "#| label: tbl-h01-primary-metric-synthesis",
    qmd_text,
    fixed = TRUE
  )[[1]],
  first_figure_position == regexpr(
    "#fig-h01-model-support",
    qmd_text,
    fixed = TRUE
  )[[1]],
  grepl("tbl-h01-primary-metric-synthesis", qmd_text, fixed = TRUE),
  grepl("primary_metric_synthesis_gt", qmd_text, fixed = TRUE),
  grepl("Participant random-intercept share", qmd_text, fixed = TRUE),
  grepl("metric-specific display scales", qmd_text, fixed = TRUE),
  grepl(
    "H01_stage3_model_support_figure_source.csv",
    qmd_text,
    fixed = TRUE
  ),
  grepl(
    "H01_stage3_site_contrast_figure_source.csv",
    qmd_text,
    fixed = TRUE
  ),
  grepl("H01_stage3_r2_figure_source.csv", qmd_text, fixed = TRUE),
  grepl(
    "H01_stage3_paired_placement_figure_source.csv",
    qmd_text,
    fixed = TRUE
  ),
  !grepl("H01_stage3_METRIC011_l10_mean_medi_", qmd_text, fixed = TRUE),
  grepl("tbl-h01-primary-publication-summary", qmd_text, fixed = TRUE),
  grepl("### Primary near-eye summary", qmd_text, fixed = TRUE),
  !grepl("### Primary publication summary", qmd_text, fixed = TRUE),
  grepl("This summary combines", qmd_text, fixed = TRUE),
  grepl("<sub>participants</sub>", qmd_text, fixed = TRUE),
  grepl("<sub>participant-days</sub>", qmd_text, fixed = TRUE),
  grepl(
    "All[[:space:]\"',]*models include nine sites",
    qmd_text,
    perl = TRUE
  ),
  grepl("Filled circles with thicker", qmd_text, fixed = TRUE),
  grepl("Panel A contains ratios", qmd_text, fixed = TRUE),
  grepl("panel B contains differences", qmd_text, fixed = TRUE),
  !grepl("facet tags A–H", qmd_text, fixed = TRUE),
  !grepl("facet tags A–M", qmd_text, fixed = TRUE),
  grepl("tbl-h01-primary-site-deviation-matrix", qmd_text, fixed = TRUE),
  grepl("Within-metric FDR-adjusted p", qmd_text, fixed = TRUE),
  !grepl("Within-metric adjusted p", qmd_text, fixed = TRUE),
  grepl("Show representative model-check details", qmd_text, fixed = TRUE),
  grepl("Show linked registration entries by topic", qmd_text, fixed = TRUE),
  grepl("Show exact formulas and model engines", qmd_text, fixed = TRUE),
  grepl("## Detailed analysis record", qmd_text, fixed = TRUE),
  grepl("## Analysis record and source data", qmd_text, fixed = TRUE),
  grepl("h01_support_orientation <- exact_samples", qmd_text, fixed = TRUE),
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
  !grepl("mder_ratio_of_integrals", qmd_text, fixed = TRUE),
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

held_order32_html_sha256 <-
  "6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa"
if (
  file.exists(html_path) &&
    !identical(artifact_sha256(html_path), held_order32_html_sha256)
) {
  html <- rvest::read_html(html_path)
  gt_tables <- rvest::html_elements(html, "table.gt_table")
  images <- rvest::html_elements(html, "img")
  image_sources <- rvest::html_attr(images, "src")
  image_alt <- rvest::html_attr(images, "alt")
  density_wrappers <- rvest::html_elements(
    html,
    "span.h01-density-thumbnail[role='img']"
  )
  density_labels <- rvest::html_attr(density_wrappers, "aria-label")
  embedded_images <- startsWith(image_sources, "data:image/png;base64,")
  resolved_images <- normalizePath(
    file.path(dirname(html_path), image_sources[!embedded_images]),
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
  synthesis_table <- rvest::html_element(
    html,
    "#tbl-h01-primary-metric-synthesis"
  )
  synthesis_table_text <- rvest::html_text2(synthesis_table)
  synthesis_images <- rvest::html_elements(synthesis_table, "tbody img")
  synthesis_image_sources <- rvest::html_attr(synthesis_images, "src")
  synthesis_density_wrappers <- rvest::html_elements(
    synthesis_table,
    "tbody span.h01-density-thumbnail[role='img']"
  )
  synthesis_density_labels <- rvest::html_attr(
    synthesis_density_wrappers,
    "aria-label"
  )
  synthesis_subscripts <- rvest::html_text2(rvest::html_elements(
    synthesis_table,
    "tbody sub"
  ))
  stopifnot(
    length(gt_tables) == 37L,
    length(rvest::html_elements(html, "table.gt_table thead")) == 37L,
    length(rvest::html_elements(html, "table.gt_table tbody")) == 37L,
    length(images) == 27L,
    sum(embedded_images) == 17L,
    sum(!is.na(image_alt) & nzchar(image_alt)) == 10L,
    length(density_wrappers) == 17L,
    all(!is.na(density_labels) & nzchar(density_labels)),
    all(!grepl("Users/zauner", image_sources[!embedded_images], fixed = TRUE)),
    all(file.exists(resolved_images)),
    length(rvest::html_elements(html, ".cell-output-error")) == 0L,
    length(rvest::html_elements(html, ".callout-note")) == 1L,
    identical(callout_titles, "Answer in brief"),
    length(rvest::html_elements(html, ".panel-tabset")) == 2L,
    length(rvest::html_elements(
      html,
      "#tbl-h01-primary-metric-synthesis table.gt_table"
    )) == 1L,
    length(synthesis_images) == 17L,
    all(startsWith(synthesis_image_sources, "data:image/png;base64,")),
    length(synthesis_density_wrappers) == 17L,
    all(
      !is.na(synthesis_density_labels) &
        nzchar(synthesis_density_labels)
    ),
    sum(synthesis_subscripts == "participants") == 34L,
    sum(synthesis_subscripts == "participant-days") == 34L,
    sum(synthesis_subscripts == "observations") == 17L,
    sum(synthesis_subscripts == "sites") == 17L,
    grepl("Melanopic daylight efficacy ratio", synthesis_table_text, fixed = TRUE),
    grepl("Participant random-intercept share", synthesis_table_text, fixed = TRUE),
    grepl("All primary models use nine sites", synthesis_table_text, fixed = TRUE),
    !grepl("mder_ratio_of_integrals", synthesis_table_text, fixed = TRUE),
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
    length(rvest::html_elements(site_matrix, "tbody tr")) == 10L,
    identical(
      site_matrix_headers,
      c(
        "Borås (SE)", "Delft (NL)", "Dortmund (DE)",
        "Tübingen (DE)", "Munich (DE)", "Madrid (ES)",
        "Izmir (TR)", "San José (CR)", "Kumasi (GH)"
      )
    ),
    length(rvest::html_elements(site_matrix, "tbody td strong")) == 21L,
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
    grepl(
      "Site, photoperiod, and latitude associations in personal light exposure",
      page_text,
      fixed = TRUE
    ),
    grepl("Answer in brief", page_text, fixed = TRUE),
    !grepl("Results in brief", page_text, fixed = TRUE),
    !grepl("Photoperiod and latitude coverage", page_text, fixed = TRUE),
    !grepl("<environment:", page_text, fixed = TRUE),
    !grepl("PILOT — NOT FOR", page_text, fixed = TRUE),
    !grepl("V0", page_text, fixed = TRUE),
    !grepl("manuscript-prepared", page_text, fixed = TRUE),
    !grepl("submitted-versus", page_text, fixed = TRUE)
  )
} else {
  stopifnot(
    file.exists(html_path),
    identical(artifact_sha256(html_path), held_order32_html_sha256)
  )
}

message("H01 reporting input and HTML structure tests passed")
