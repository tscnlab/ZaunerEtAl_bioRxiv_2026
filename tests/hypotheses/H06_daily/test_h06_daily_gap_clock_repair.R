#!/usr/bin/env Rscript

# Focused identity, scope, and scientific-contract checks for the targeted
# H06_daily gap clock-hour repair. This test does not fit or refit a model.

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

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_gap_clock_repair_contract.R"
))

h06d_gap_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "Focused repair verification requires R 4.6.1"
)
paths <- h06d_gap_paths(root)
direct <- h06d_gap_verify_direct_pins(root)
protected <- h06d_gap_verify_protected_1011(root, "focused_test")
g2a <- h06d_gap_verify_manifest(
  root,
  file.path(
    paths$manifests,
    "H06_daily_h01_diagnostic_alignment_output_manifest.csv"
  ),
  "focused_test_g2a_outputs"
)

verify_manifest <- function(relative_path, expected_rows = NULL) {
  absolute <- file.path(root, relative_path)
  h06d_gap_assert(file.exists(absolute), "Manifest missing: `%s`", relative_path)
  manifest <- readr::read_csv(absolute, show_col_types = FALSE)
  if (!is.null(expected_rows)) {
    h06d_gap_assert(
      nrow(manifest) == expected_rows,
      "Manifest `%s` has %d rather than %d rows",
      relative_path,
      nrow(manifest),
      expected_rows
    )
  }
  member_paths <- file.path(root, manifest$relative_path)
  observed_sha <- vapply(member_paths, h06d_gap_sha256, character(1L))
  observed_bytes <- as.numeric(file.info(member_paths)$size)
  h06d_gap_assert(
    all(file.exists(member_paths)) &&
      identical(unname(observed_sha), manifest$sha256) &&
      identical(observed_bytes, manifest$bytes),
    "Manifest identity verification failed: `%s`",
    relative_path
  )
  manifest
}

input_manifest <- readr::read_csv(
  file.path(paths$manifests, "H06_daily_gap_clock_repair_input_manifest.csv"),
  show_col_types = FALSE
)
h06d_gap_assert(
  nrow(input_manifest) == 25L && all(input_manifest$identity_verified),
  "The repair input manifest is incomplete"
)
code_manifest <- verify_manifest(
  "artifacts/12_manifests/H06_daily/H06_daily_gap_clock_repair_code_manifest.csv"
)
software_manifest <- readr::read_csv(
  file.path(paths$manifests, "H06_daily_gap_clock_repair_software_manifest.csv"),
  show_col_types = FALSE
)
output_manifest <- verify_manifest(
  "artifacts/12_manifests/H06_daily/H06_daily_gap_clock_repair_output_manifest.csv"
)
report_manifest <- verify_manifest(
  "audit/hypotheses/H06_daily/H06_daily_gap_clock_repair_report_manifest.csv"
)
h06d_gap_assert(
  all(software_manifest$r_version == "4.6.1") &&
    any(software_manifest$package == "sandwich") &&
    any(software_manifest$package == "glmmTMB") &&
    !"artifacts/12_manifests/H06_daily/H06_daily_gap_clock_repair_output_manifest.csv" %in%
      output_manifest$relative_path &&
    !"audit/hypotheses/H06_daily/H06_daily_gap_clock_repair_report_manifest.csv" %in%
      report_manifest$relative_path,
  "A manifest is circular or the software contract is incomplete"
)

allowed_output <- grepl(
  paste0(
    "^(audit/hypotheses/H06_daily/|scripts/hypotheses/H06_daily/|",
    "tests/hypotheses/H06_daily/|artifacts/(06_model_data|07_models|",
    "08_diagnostics|09_tables|10_figures|10_source_data|12_manifests)/",
    "H06_daily/)"
  ),
  output_manifest$relative_path
)
h06d_gap_assert(
  all(allowed_output) &&
    !any(grepl("/H06/", output_manifest$relative_path, fixed = TRUE)),
  "The repair output manifest reaches outside H06_daily-owned paths"
)

read_diag <- function(name) {
  readr::read_csv(file.path(paths$diagnostic, name), show_col_types = FALSE)
}
read_table <- function(name) {
  readr::read_csv(file.path(paths$tables, name), show_col_types = FALSE)
}

classification <- read_diag(
  "H06_daily_gap_clock_repair_h01_classification.csv"
)
repair_classification <- read_diag(
  "H06_daily_gap_clock_repair_90_cell_classification.csv"
)
visual <- read_diag("H06_daily_gap_clock_repair_visual_review.csv")
plot_index <- read_diag("H06_daily_gap_clock_repair_visual_plot_index.csv")
atlas_index <- read_diag("H06_daily_gap_clock_repair_visual_atlas_index.csv")
frame_invariance <- read_diag(
  "H06_daily_gap_clock_repair_378_frame_invariance.csv"
)
change_audit <- read_diag(
  "H06_daily_gap_clock_repair_90_cell_change_audit.csv"
)
base_index <- read_diag("H06_daily_gap_clock_repair_base_checkpoint.csv")
influence_index <- read_diag(
  "H06_daily_gap_clock_repair_influence_checkpoint.csv"
)
influence_results <- read_diag(
  "H06_daily_gap_clock_repair_influence_results.csv"
)
scale <- read_table("H06_daily_gap_clock_repair_scale_equivariance.csv")
residual_scale <- read_diag(
  "H06_daily_gap_clock_repair_residual_scale_equivariance.csv"
)
bh <- read_table("H06_daily_gap_clock_repair_bh_families.csv")
historical_bh <- read_table("H06_daily_non_l10_production_bh_families.csv")
effects <- read_table("H06_daily_gap_clock_repair_effects.csv")
raw_tests <- read_table("H06_daily_gap_clock_repair_raw_tests.csv")

h06d_gap_assert(
  nrow(classification) == 468L && !anyDuplicated(classification$frame_key) &&
    all(classification$h01_diagnostic_class == "WARN_REVIEW") &&
    !any(classification$hard_gate_failed) &&
    nrow(repair_classification) == 90L &&
    all(repair_classification$timing_construct_unit_valid) &&
    all(repair_classification$base_fit_available) &&
    all(repair_classification$base_numerical_estimability) &&
    all(repair_classification$required_clock_support) &&
    all(repair_classification$observed_response_support) &&
    all(repair_classification$h01_diagnostic_class == "WARN_REVIEW") &&
    !any(repair_classification$hard_gate_failed),
  "The H01-aligned repaired classification is incorrect"
)
h06d_gap_assert(
  nrow(visual) == 90L &&
    all(visual$visual_residual_verdict == "REVIEW_LIMITATION") &&
    !any(visual$numeric_threshold_set_verdict) &&
    all(visual$review_method == paste(
      "Direct visual inspection of every indexed residual-vs-fitted and",
      "normal Q-Q display; no numeric verdict rule"
    )) &&
    nrow(plot_index) == 90L && nrow(atlas_index) == 10L,
  "The manual residual-review contract is incomplete"
)

plot_paths <- file.path(root, plot_index$diagnostic_plot_relative_path)
source_paths <- file.path(root, plot_index$source_data_relative_path)
atlas_paths <- file.path(root, atlas_index$atlas_relative_path)
h06d_gap_assert(
  identical(
    unname(vapply(plot_paths, h06d_gap_sha256, character(1L))),
    plot_index$diagnostic_plot_sha256
  ) &&
    identical(
      unname(vapply(source_paths, h06d_gap_sha256, character(1L))),
      plot_index$source_data_sha256
    ) &&
    identical(
      unname(vapply(atlas_paths, h06d_gap_sha256, character(1L))),
      atlas_index$atlas_sha256
    ),
  "A residual plot, atlas, or paired source-data file changed"
)

h06d_gap_assert(
  nrow(frame_invariance) == 378L && all(frame_invariance$byte_identical) &&
    nrow(change_audit) == 90L &&
    all(change_audit$membership_coding_attributes_identical) &&
    all(change_audit$response_source_multiplier == 60) &&
    all(change_audit$response_source_relation_verified) &&
    all(change_audit$response_transform_verified) &&
    !any(change_audit$shared_source_modified),
  "The 90/378 frame boundary is not exact"
)
h06d_gap_assert(
  nrow(base_index) == 90L && all(base_index$outer_success) &&
    nrow(effects) == 90L && nrow(raw_tests) == 180L &&
    nrow(influence_index) == 90L &&
    sum(influence_index$completed_refits) == 12837L &&
    sum(influence_index$failed_refits) == 0L &&
    nrow(influence_results) == 12837L &&
    all(scale$inference_scale_equivariant_within_1e_10) &&
    nrow(residual_scale) == 90L &&
    all(residual_scale$scale_equivariance_verified),
  "A repaired model, influence, or scale-equivalence component is incomplete"
)

key <- c("dataset_id", "predictor_id", "test_type", "metric_slot")
bh_compare <- bh |>
  dplyr::select(
    dplyr::all_of(key),
    repaired_raw = "raw_p_value",
    repaired_q = "bh_adjusted_p_value"
  ) |>
  dplyr::left_join(
    historical_bh |>
      dplyr::select(
        dplyr::all_of(key),
        historical_raw = "raw_p_value",
        historical_q = "bh_adjusted_p_value"
      ),
    by = key,
    relationship = "one-to-one"
  )
primary <- bh_compare$dataset_id == "primary"
gap_unaffected <- bh_compare$dataset_id == "gap_timing_unaware" &
  !bh_compare$metric_slot %in% 9:13
mder <- bh_compare$metric_slot == 15L
l10 <- bh$metric_slot == 3L
bh_boundary_checks <- c(
  rows_180 = nrow(bh) == 180L,
  families_12 = dplyr::n_distinct(bh$multiplicity_family_id) == 12L,
  required_slots_15 = all(bh$family_slots_required == 15L),
  available_slots_14 = all(bh$family_slots_available == 14L),
  construct_valid = all(bh$multiplicity_family_construct_valid),
  raw_repaired_30 = sum(bh$raw_slot_repaired) == 30L,
  gap_rows_recomputed_90 = sum(bh$bh_family_recomputed) == 90L,
  primary_raw_exact = identical(
    bh_compare$repaired_raw[primary],
    bh_compare$historical_raw[primary]
  ),
  primary_q_exact = identical(
    bh_compare$repaired_q[primary],
    bh_compare$historical_q[primary]
  ),
  unaffected_gap_raw_exact = identical(
    bh_compare$repaired_raw[gap_unaffected],
    bh_compare$historical_raw[gap_unaffected]
  ),
  mder_raw_exact = identical(
    bh_compare$repaired_raw[mder],
    bh_compare$historical_raw[mder]
  ),
  l10_raw_na = all(is.na(bh$raw_p_value[l10])),
  l10_q_na = all(is.na(bh$bh_adjusted_p_value[l10]))
)
h06d_gap_assert(
  all(bh_boundary_checks),
  "The repaired BH family boundary failed: %s",
  paste(names(bh_boundary_checks)[!bh_boundary_checks], collapse = ", ")
)

primary_gap_timing <- bh |>
  dplyr::filter(
    .data$dataset_id == "gap_timing_unaware",
    .data$metric_slot %in% 9:13
  )
h06d_gap_assert(
  sum(primary_gap_timing$test_type == "association" &
        primary_gap_timing$predictor_id == "work_free_day" &
        primary_gap_timing$h01_claim_eligible) == 5L &&
    sum(primary_gap_timing$test_type == "association" &
        primary_gap_timing$predictor_id ==
          "previous_sleep_duration_centered_h" &
        primary_gap_timing$h01_claim_eligible) == 5L &&
    sum(primary_gap_timing$test_type == "association" &
        primary_gap_timing$predictor_id == "activity_status" &
        primary_gap_timing$h01_claim_eligible) == 0L &&
    sum(primary_gap_timing$test_type == "site_heterogeneity" &
        primary_gap_timing$h01_claim_eligible) == 0L,
  "The repaired five-outcome timing result pattern changed"
)

html_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/14_gap_clock_repair.html"
)
document <- xml2::read_html(html_path)
images <- xml2::xml_find_all(document, "//img")
alt_text <- xml2::xml_attr(images, "alt")
h06d_gap_assert(
  length(images) == 10L && all(!is.na(alt_text) & nzchar(alt_text)) &&
    length(xml2::xml_find_all(document, "//table")) >= 7L,
  "The rendered report is missing an atlas alt text or required table"
)

h06d_gap_assert(
  nrow(direct) == 25L && all(direct$identity_verified) &&
    nrow(protected) == 1011L && all(protected$identity_verified) &&
    nrow(g2a) == 997L && all(g2a$identity_verified),
  "A sealed input or historical identity changed"
)

cat(paste0(
  "H06_daily gap clock repair focused verification PASS: 25 direct pins; ",
  "90 repaired cells; 378 invariant cells; 30 repaired raw slots; ",
  "six recomputed gap families; 12 named 15-slot families; ",
  "12,837 deletion refits; 90 manual residual verdicts; ",
  "1,011 protected identities; 997 frozen G2A outputs; ",
  nrow(output_manifest), " non-circular repair outputs.\n"
))
