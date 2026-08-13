#!/usr/bin/env Rscript

# Focused no-refit verification of the revised H06_daily Stage 3 reader report.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c("digest", "dplyr", "readr", "tidyr", "xml2")
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

count_fixed <- function(text, pattern) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) 0L else length(matches)
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
      identical(
        unname(vapply(paths, sha256, character(1L))),
        manifest$sha256
      ) &&
      identical(as.numeric(file.info(paths)$size), manifest$bytes),
    paste0(label, " contains a missing or changed identity")
  )
}

assert(
  identical(as.character(getRversion()), "4.6.1"),
  "The Stage 3 reader verification requires R 4.6.1"
)

source_dir <- "artifacts/11_source_data/H06_daily"
manifest_dir <- "artifacts/12_manifests/H06_daily"
primary <- read_project_csv(file.path(source_dir, "H06_daily_stage3_primary_results.csv"))
placement <- read_project_csv(file.path(source_dir, "H06_daily_stage3_placement_results.csv"))
gap <- read_project_csv(file.path(source_dir, "H06_daily_stage3_gap_results.csv"))
gap_changes <- read_project_csv(file.path(source_dir, "H06_daily_stage3_gap_decision_changes.csv"))
families_summary <- read_project_csv(file.path(source_dir, "H06_daily_stage3_family_summary.csv"))
diagnostics <- read_project_csv(file.path(source_dir, "H06_daily_stage3_diagnostic_summary.csv"))
sample_roles <- read_project_csv(file.path(source_dir, "H06_daily_stage3_sample_role_summary.csv"))
fdr_overview <- read_project_csv(file.path(source_dir, "H06_daily_stage3_fdr_overview_figure.csv"))
primary_site <- read_project_csv(file.path(source_dir, "H06_daily_stage3_primary_site_interaction_estimates.csv"))
primary_site_summary <- read_project_csv(file.path(source_dir, "H06_daily_stage3_primary_site_interaction_summary.csv"))
primary_site_deviations <- read_project_csv(file.path(
  source_dir,
  "H06_daily_stage3_primary_site_deviation_figure.csv"
))
primary_site_deviation_alt <- read_project_csv(file.path(
  source_dir,
  "H06_daily_stage3_primary_site_deviation_figure_alt_text.csv"
))
joint_stability <- read_project_csv(file.path(source_dir, "H06_daily_joint_context_exploratory_stability.csv"))
joint_site <- read_project_csv(file.path(source_dir, "H06_daily_joint_context_exploratory_site_estimates.csv"))
joint_site_summary <- read_project_csv(file.path(source_dir, "H06_daily_stage3_joint_site_interaction_summary.csv"))
joint_families <- read_project_csv("artifacts/09_tables/H06_daily/H06_daily_joint_context_exploratory_family_summary.csv")
main_comparison <- read_project_csv(file.path(source_dir, "H06_daily_stage3_main_hourly_comparison.csv"))
temporal_gamm <- read_project_csv(file.path(source_dir, "H06_daily_stage3_temporal_gamm_summary.csv"))

input_manifest <- read_project_csv(file.path(manifest_dir, "H06_daily_stage3_input_manifest.csv"))
revision_input_manifest <- read_project_csv(file.path(manifest_dir, "H06_daily_stage3_revision_input_manifest.csv"))
figure_qa <- read_project_csv(file.path(manifest_dir, "H06_daily_stage3_revision_figure_readability_qa.csv"))
source_manifest <- read_project_csv(file.path(manifest_dir, "H06_daily_stage3_source_data_manifest.csv"))
software_manifest <- read_project_csv(file.path(manifest_dir, "H06_daily_stage3_software_manifest.csv"))
render_qa <- read_project_csv(file.path(manifest_dir, "H06_daily_stage3_render_qa.csv"))
output_manifest <- read_project_csv(file.path(manifest_dir, "H06_daily_stage3_output_manifest.csv"))
accepted_families <- read_project_csv("artifacts/09_tables/H06_daily/H06_daily_gap_clock_repair_bh_families.csv")

assert(
  nrow(input_manifest) == 23L &&
    all(input_manifest$verification_status == "PASS") &&
    all(input_manifest$expected_sha256 == input_manifest$actual_sha256),
  "The accepted Stage 3 input contract is incomplete or changed"
)
assert(
  nrow(revision_input_manifest) == 20L &&
    all(revision_input_manifest$verification_status == "PASS") &&
    all(revision_input_manifest$expected_sha256 == revision_input_manifest$actual_sha256),
  "The Stage 3 revision input and preservation contract is incomplete or changed"
)
verify_identity_manifest(source_manifest, "The revised source-data manifest")
verify_identity_manifest(output_manifest, "The revised output manifest")
assert(
  nrow(source_manifest) == 23L &&
    nrow(software_manifest) == 12L &&
    nrow(render_qa) == 18L &&
    nrow(output_manifest) == 54L &&
    !anyDuplicated(source_manifest$relative_path) &&
    !anyDuplicated(output_manifest$relative_path) &&
    !"artifacts/12_manifests/H06_daily/H06_daily_stage3_output_manifest.csv" %in%
      output_manifest$relative_path &&
    sum(render_qa$status == "PASS") == 17L &&
    sum(render_qa$status == "DISCLOSED_LIMITATION") == 1L &&
    any(software_manifest$component == "R" & software_manifest$version == "4.6.1") &&
    any(software_manifest$component == "Quarto" & software_manifest$version == "1.9.37"),
  "A revised Stage 3 provenance, software, or render-QA manifest is malformed"
)

assert(
  nrow(primary) == 45L &&
    nrow(placement) == 180L &&
    nrow(gap) == 45L &&
    nrow(gap_changes) == 3L &&
    nrow(families_summary) == 12L &&
    nrow(sample_roles) == 5L &&
    nrow(fdr_overview) == 90L &&
    nrow(primary_site) == 90L &&
    nrow(primary_site_summary) == 10L &&
    nrow(primary_site_deviations) == 90L &&
    nrow(primary_site_deviation_alt) == 1L &&
    nrow(joint_stability) == 45L &&
    nrow(joint_site) == 378L &&
    nrow(joint_site_summary) == 6L &&
    nrow(joint_families) == 6L &&
    nrow(main_comparison) == 3L &&
    nrow(temporal_gamm) == 4L &&
    all(table(primary$predictor_id) == 15L) &&
    all(table(gap$predictor_id) == 15L) &&
    all(table(placement$run_id) == 45L),
  "A revised Stage 3 display grid is incomplete"
)

# The accepted primary and gap inference must remain byte-for-byte equivalent
# at the displayed p-value, FDR, decision, and eligibility level.
comparison_key <- c("dataset_id", "predictor_id", "metric_slot")
reader_inference <- dplyr::bind_rows(primary, gap) |>
  dplyr::select(
    dplyr::all_of(comparison_key),
    association_raw = association_raw_p_value,
    association_q = association_bh_adjusted_p_value,
    association_supported = association_fdr_supported,
    association_eligible = association_h01_claim_eligible,
    heterogeneity_raw = site_heterogeneity_raw_p_value,
    heterogeneity_q = site_heterogeneity_bh_adjusted_p_value,
    heterogeneity_supported = site_heterogeneity_fdr_supported,
    heterogeneity_eligible = site_heterogeneity_h01_claim_eligible
  ) |>
  dplyr::arrange(.data$dataset_id, .data$predictor_id, .data$metric_slot)
accepted_inference <- accepted_families |>
  dplyr::select(
    dplyr::all_of(comparison_key),
    test_type,
    raw_p_value,
    bh_adjusted_p_value,
    fdr_supported,
    h01_claim_eligible
  ) |>
  tidyr::pivot_wider(
    names_from = test_type,
    values_from = c(raw_p_value, bh_adjusted_p_value, fdr_supported, h01_claim_eligible),
    names_glue = "{test_type}_{.value}"
  ) |>
  dplyr::transmute(
    dplyr::across(dplyr::all_of(comparison_key)),
    association_raw = association_raw_p_value,
    association_q = association_bh_adjusted_p_value,
    association_supported = association_fdr_supported,
    association_eligible = association_h01_claim_eligible,
    heterogeneity_raw = site_heterogeneity_raw_p_value,
    heterogeneity_q = site_heterogeneity_bh_adjusted_p_value,
    heterogeneity_supported = site_heterogeneity_fdr_supported,
    heterogeneity_eligible = site_heterogeneity_h01_claim_eligible
  ) |>
  dplyr::arrange(.data$dataset_id, .data$predictor_id, .data$metric_slot)
assert(
  isTRUE(all.equal(reader_inference, accepted_inference)),
  "A displayed accepted raw p-value, FDR q-value, or decision changed"
)

l10 <- dplyr::bind_rows(primary, gap) |>
  dplyr::filter(.data$metric_slot == 3L)
mder <- dplyr::bind_rows(primary, gap) |>
  dplyr::filter(.data$metric_slot == 15L)
assert(
  nrow(l10) == 6L &&
    all(l10$result_status == "NON_ESTIMABLE_COMPONENT_FAILURE") &&
    all(is.na(l10$estimate)) &&
    all(is.na(l10$association_raw_p_value)) &&
    all(is.na(l10$association_bh_adjusted_p_value)) &&
    nrow(mder) == 6L &&
    all(mder$source_branch == "accepted_frozen_mder") &&
    all(mder$result_status == "ESTIMABLE_FROZEN_MDER"),
  "The accepted L10 or MDER disposition changed"
)

# Check the newly exposed primary site interactions, including the author's
# requested mean-melEDI example.
mean_work_free_sites <- primary_site |>
  dplyr::filter(.data$metric_slot == 1L, .data$predictor_id == "work_free_day") |>
  dplyr::arrange(.data$display_order)
assert(
  nrow(mean_work_free_sites) == 9L &&
    all(mean_work_free_sites$display_estimate < 1) &&
    identical(
      mean_work_free_sites$display_name[mean_work_free_sites$pointwise_interval_excludes_null],
      c("Dortmund (DE)", "Tübingen (DE)", "Madrid (ES)", "Kumasi (GH)")
    ) &&
    all(primary_site_summary$global_interaction_bh_q < 0.05) &&
    all(primary_site_summary$sites_pointwise_excluding_null >= 1L),
  "The primary site-interaction interpretation changed"
)

primary_site_text <- unlist(primary_site_summary[c(
  "pointwise_adjustment_below_equal_site",
  "pointwise_adjustment_above_equal_site",
  "pointwise_adjustment_compatible_with_equal_site"
)], use.names = FALSE)
joint_site_text <- unlist(joint_site_summary[c(
  "pointwise_comparison_lower",
  "pointwise_comparison_higher",
  "pointwise_compatible_with_null"
)], use.names = FALSE)
nonempty_compatible <- c(
  primary_site_summary$pointwise_adjustment_compatible_with_equal_site,
  joint_site_summary$pointwise_compatible_with_null
)
nonempty_compatible <- nonempty_compatible[nonempty_compatible != "None"]
mean_work_free_summary <- primary_site_summary |>
  dplyr::filter(.data$metric_slot == 1L, .data$predictor_id == "work_free_day")
mean_work_free_deviations <- primary_site_deviations |>
  dplyr::filter(.data$metric_slot == 1L, .data$predictor_id == "work_free_day") |>
  dplyr::arrange(.data$display_order)
deviation_geometric_means <- primary_site_deviations |>
  dplyr::group_by(.data$metric_id, .data$predictor_id) |>
  dplyr::summarise(
    geometric_mean_adjustment = exp(mean(log(.data$site_adjustment_factor))),
    .groups = "drop"
  )
assert(
  count_fixed(paste(primary_site_text, collapse = ""), "●") == 90L &&
    count_fixed(paste(joint_site_text, collapse = ""), "●") == 54L &&
    all(grepl("</span>&nbsp;", c(primary_site_text, joint_site_text), fixed = TRUE) |
      c(primary_site_text, joint_site_text) == "None") &&
    all(
      grepl("(", nonempty_compatible, fixed = TRUE) &
        grepl(" to ", nonempty_compatible, fixed = TRUE) &
        grepl(")", nonempty_compatible, fixed = TRUE)
    ) &&
    nrow(mean_work_free_summary) == 1L &&
    nrow(mean_work_free_deviations) == 9L &&
    isTRUE(all.equal(
      mean_work_free_summary$equal_site_display_estimate[[1L]],
      exp(mean(log(mean_work_free_sites$display_estimate))),
      tolerance = 1e-12
    )) &&
    all(abs(deviation_geometric_means$geometric_mean_adjustment - 1) < 1e-12) &&
    all(abs(
      mean_work_free_deviations$site_specific_comparison_reference -
        mean_work_free_deviations$equal_site_comparison_reference *
          mean_work_free_deviations$site_adjustment_factor
    ) < 1e-12) &&
    identical(
      mean_work_free_deviations$display_name[
        mean_work_free_deviations$site_adjustment_pointwise_classification ==
          "above_equal_site"
      ],
      "Delft (NL)"
    ) &&
    identical(
      mean_work_free_deviations$display_name[
        mean_work_free_deviations$site_adjustment_pointwise_classification ==
          "below_equal_site"
      ],
      c("Madrid (ES)", "Kumasi (GH)")
    ) &&
    sum(
      primary_site_deviations$site_adjustment_pointwise_classification ==
        "below_equal_site"
    ) == 13L &&
    sum(
      primary_site_deviations$site_adjustment_pointwise_classification ==
        "above_equal_site"
    ) == 11L &&
    sum(
      primary_site_deviations$site_adjustment_pointwise_classification ==
        "compatible_with_equal_site"
    ) == 66L &&
    grepl("13 are pointwise below 1", primary_site_deviation_alt$alt_text, fixed = TRUE) &&
    grepl("11 are pointwise above 1", primary_site_deviation_alt$alt_text, fixed = TRUE),
  paste(
    "The submitted-colour site markers, compatible-null CIs, or full",
    "interaction contrast scale changed"
  )
)

assert(
  all(joint_families$named_slots == 15L) &&
    all(joint_families$estimable_slots == 14L) &&
    all(joint_families$named_na_slots == 1L) &&
    all(joint_families$family_valid) &&
    identical(
      as.integer(joint_families$fdr_supported_slots),
      c(10L, 6L, 6L, 0L, 10L, 0L)
    ) &&
    sum(joint_stability$covariate_stability == "STABLE_LT_1_SE") == 34L &&
    sum(joint_stability$covariate_stability == "SUBSTANTIAL_LIMITATION_1_TO_LT_2_SE") == 7L &&
    sum(joint_stability$covariate_stability == "UNSTABLE_GE_2_SE_OR_DIRECTION_REVERSAL") == 1L &&
    sum(joint_stability$covariate_stability == "NAMED_NA_ACCEPTED_L10_ESTIMAND_NOT_REPLACED") == 3L &&
    nrow(joint_site_summary) == 6L &&
    sum(
      joint_site_summary$reporting_role ==
        "Descriptive MDER only; major heavy-tail and site-influence limitation"
    ) == 1L,
  "The joint-context family, stability, or site summary changed"
)

mean_comparison <- main_comparison |>
  dplyr::arrange(.data$predictor_order)
assert(
  identical(
    mean_comparison$predictor_id,
    c("work_free_day", "activity_status", "previous_sleep_duration_centered_h")
  ) &&
    identical(
      mean_comparison$hourly_uses_interaction,
      c(TRUE, FALSE, FALSE)
    ) &&
    identical(
      mean_comparison$daily_predictor_specific_uses_interaction,
      c(TRUE, TRUE, FALSE)
    ) &&
    identical(
      mean_comparison$daily_joint_uses_interaction,
      c(TRUE, FALSE, FALSE)
    ) &&
    isTRUE(all.equal(
      mean_comparison$hourly_selected_estimate,
      c(1.1549572728, 2.0620957998, 0.9777939075),
      tolerance = 1e-9
    )) &&
    isTRUE(all.equal(
      mean_comparison$daily_predictor_specific_selected_estimate,
      c(0.6972652672, 1.2226049389, 0.8877882984),
      tolerance = 1e-9
    )) &&
    isTRUE(all.equal(
      mean_comparison$daily_joint_selected_estimate,
      c(0.7341983028, 1.1561579659, 0.9018934286),
      tolerance = 1e-9
    )) &&
    all(
      grepl(
        "interaction model; equal-site full contrast",
        c(
          mean_comparison$hourly_selected_model[[1L]],
          mean_comparison$daily_predictor_specific_selected_model[1:2],
          mean_comparison$daily_joint_selected_model[[1L]]
        ),
        fixed = TRUE
      )
    ),
  "The selected main-H06 comparison changed"
)

assert(
  identical(
    temporal_gamm$estimand_id,
    c(
      "free_minus_work",
      "active_minus_sedentary",
      "sleep_within_plus_1h",
      "sleep_between_plus_1h"
    )
  ) &&
    all(temporal_gamm$bh_decision) &&
    all(temporal_gamm$observations_30_minute == 33057L) &&
    all(temporal_gamm$participant_days == 715L) &&
    all(temporal_gamm$participants == 137L) &&
    all(temporal_gamm$sites == 9L) &&
    all(temporal_gamm$evaluated_half_hour_midpoints == 48L) &&
    identical(as.integer(temporal_gamm$pointwise_bins_excluding_null), c(35L, 29L, 24L, 9L)) &&
    all(
      temporal_gamm$interval_scope ==
        "pointwise 95% confidence intervals over 48 half-hour midpoints"
    ),
  "The accepted temporal GAMM summary changed"
)

overall_diag <- diagnostics |>
  dplyr::filter(.data$domain == "Overall H01-aligned cell status")
visual_diag <- diagnostics |>
  dplyr::filter(.data$domain == "Visual residual review")
assert(
  nrow(overall_diag) == 1L &&
    overall_diag$cells == 468L &&
    overall_diag$classification == "Acceptable with limitations" &&
    nrow(visual_diag) == 1L &&
    visual_diag$cells == 468L &&
    visual_diag$classification == "REVIEW_LIMITATION",
  "The accepted H01-aligned diagnostic summary changed"
)

assert(
  nrow(figure_qa) == 5L &&
    all(figure_qa$visual_review_status == "PASS") &&
    all(figure_qa$paired_source_present) &&
    all(figure_qa$alt_text_present) &&
    all(figure_qa$width_px >= 1800L) &&
    all(figure_qa$height_px >= 1000L) &&
    identical(
      unname(vapply(file.path(root, figure_qa$relative_path), sha256, character(1L))),
      figure_qa$figure_sha256
    ) &&
    identical(
      unname(vapply(
        file.path(root, figure_qa$source_data_relative_path),
        sha256,
        character(1L)
      )),
      figure_qa$source_data_sha256
    ),
  "Figure readability, alt text, source pairing, or identity QA failed"
)

qmd_path <- file.path(root, "notebooks/hypotheses/H06_daily.qmd")
html_path <- file.path(root, "notebooks/hypotheses/H06_daily.html")
assert(file.exists(qmd_path) && file.exists(html_path), "The Stage 3 source or HTML is missing")
qmd_lines <- readLines(qmd_path, warn = FALSE)
qmd <- paste(qmd_lines, collapse = "\n")
in_r_chunk <- FALSE
r_code_lines <- character()
for (line in qmd_lines) {
  if (!in_r_chunk && grepl("^```\\{r", line, perl = TRUE)) {
    in_r_chunk <- TRUE
    next
  }
  if (in_r_chunk && grepl("^```[[:space:]]*$", line, perl = TRUE)) {
    in_r_chunk <- FALSE
    next
  }
  if (in_r_chunk) {
    r_code_lines <- c(r_code_lines, line)
  }
}
r_code <- paste(r_code_lines, collapse = "\n")
assert(
  grepl('{.callout-note appearance="simple" icon="false" title="Answer in brief"}', qmd, fixed = TRUE) &&
    grepl("[main H06 analysis](H06.qmd)", qmd, fixed = TRUE) &&
    grepl("../preregistration_deviations.qmd#dev-015", qmd, fixed = TRUE) &&
    grepl("Exploratory mutually adjusted daily analysis", qmd, fixed = TRUE) &&
    grepl("Exploratory 30-minute time-of-day GAMM", qmd, fixed = TRUE) &&
    grepl("Comparison with the selected main H06 analysis", qmd, fixed = TRUE) &&
    grepl("site adjustment factor", qmd, fixed = TRUE) &&
    grepl("H06_daily_stage3_primary_site_deviations.png", qmd, fixed = TRUE) &&
    !grepl("\\bV0\\b", qmd, perl = TRUE) &&
    !grepl(
      "(^|[^[:alnum:]_])(lmer|glmer|glmmTMB|bam|gam|p\\.adjust)[[:space:]]*\\(",
      r_code,
      perl = TRUE
    ),
  "The revised reader source lacks the required framing or contains fitting code"
)

html <- xml2::read_html(html_path)
images <- xml2::xml_find_all(html, "//main//img")
callout <- xml2::xml_find_all(
  html,
  paste0(
    "//div[contains(concat(' ', normalize-space(@class), ' '), ' callout-note ')",
    " and contains(concat(' ', normalize-space(@class), ' '), ' no-icon ')]",
    "//*[contains(@class, 'callout-title') and ",
    "contains(normalize-space(.), 'Answer in brief')]"
  )
)
assert(
  length(xml2::xml_find_all(html, "//h1")) == 1L &&
    length(xml2::xml_find_all(html, "//main//table")) == 14L &&
    length(images) == 5L &&
    all(nzchar(xml2::xml_attr(images, "alt"))) &&
    all(startsWith(xml2::xml_attr(images, "src"), "data:image/png;base64,")) &&
    length(callout) == 1L,
  "The rendered reader structure, note callout, or figure accessibility failed"
)
main_text <- xml2::xml_text(xml2::xml_find_first(html, "//main"))
site_color_dots <- xml2::xml_find_all(
  html,
  paste0(
    "//main//span[contains(@style, 'color:') and ",
    "contains(normalize-space(.), '●')]"
  )
)
assert(
  !grepl("\\bV0\\b", main_text, perl = TRUE) &&
    !grepl("\\b(gate|pilot|repair|sealed|frozen)\\b", main_text, ignore.case = TRUE, perl = TRUE) &&
    grepl("pointwise 95% confidence intervals", main_text, fixed = TRUE) &&
    grepl("none is simultaneous", main_text, fixed = TRUE) &&
    grepl("Dortmund", main_text, fixed = TRUE) &&
    grepl("Tübingen", main_text, fixed = TRUE) &&
    grepl("Madrid", main_text, fixed = TRUE) &&
    grepl("Kumasi", main_text, fixed = TRUE) &&
    length(site_color_dots) == 144L &&
    count_fixed(main_text, "Interaction model: equal-site full contrast") == 4L &&
    grepl("Multiplying the equal-site ratio", main_text, fixed = TRUE) &&
    grepl("recovers the site", main_text, fixed = TRUE) &&
    grepl("not a multiplier", main_text, fixed = TRUE) &&
    grepl("13 are pointwise below 1", xml2::xml_attr(images[[4L]], "alt"), fixed = TRUE),
  "The rendered interval, site, or reader-facing language is wrong"
)

cat(
  paste0(
    "PASS: revised H06_daily Stage 3 reader report verified under R ",
    as.character(getRversion()),
    ": accepted primary and gap inference preserved; 10 primary site blocks; ",
    "six exploratory joint families; four temporal GAMM estimands; three main-",
    "H06 comparison rows; 90 site-to-equal-site adjustments; 144 submitted-",
    "colour site markers; 14 tables; and five accessible paired-source figures.\n"
  )
)
