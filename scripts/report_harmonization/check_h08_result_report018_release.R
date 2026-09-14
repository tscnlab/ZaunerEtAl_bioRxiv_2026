#!/usr/bin/env Rscript

options(warn = 2)

assert_true <- function(value, message) {
  if (!isTRUE(value)) {
    stop(message, call. = FALSE)
  }
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  mustWork = TRUE
)
assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("R 4.6.1 required, found %s", getRversion())
)
assert_true(requireNamespace("digest", quietly = TRUE), "digest is required")

pins_path <- file.path(
  root,
  "audit/report_harmonization/report018_h08_result_release_pins.csv"
)
pins <- read.csv(pins_path, stringsAsFactors = FALSE)
assert_true(nrow(pins) == 31L, "H08 release must contain 31 pins")
assert_true(
  identical(names(pins), c("role", "relative_path", "sha256", "bytes")),
  "H08 release-pin columns changed"
)
assert_true(!anyDuplicated(pins$role), "H08 release-pin roles are not unique")
assert_true(
  !anyDuplicated(pins$relative_path),
  "H08 release-pin paths are not unique"
)
pin_files <- file.path(root, pins$relative_path)
assert_true(all(file.exists(pin_files)), "An H08 release-pin path is missing")
assert_true(
  all(as.numeric(file.info(pin_files)$size) == pins$bytes),
  "An H08 release-pin byte count changed"
)
assert_true(
  identical(
    unname(vapply(pin_files, sha256_file, character(1))),
    pins$sha256
  ),
  "An H08 release-pin SHA-256 changed"
)

qmd_path <- file.path(root, "notebooks/hypotheses/H08.qmd")
companion_path <- file.path(
  root,
  "audit/hypotheses/H08/H08_analysis_preparation.qmd"
)
qmd_lines <- readLines(qmd_path, warn = FALSE)
qmd_text <- paste(qmd_lines, collapse = "\n")
qmd_text_normalized <- gsub("[[:space:]]+", " ", qmd_text)
companion_text <- paste(
  readLines(companion_path, warn = FALSE),
  collapse = "\n"
)

source(file.path(
  root,
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
))
chunks <- extract_executable_r_chunks(qmd_lines)
assert_true(length(chunks) == 22L, "H08 result must contain 22 R chunks")
for (index in seq_along(chunks)) {
  parse(text = chunks[[index]], keep.source = FALSE)
}

table_endpoints <- sub(
  "#| label: ",
  "",
  qmd_lines[startsWith(qmd_lines, "#| label: tbl-h08-")],
  fixed = TRUE
)
figure_endpoints <- sub(
  "#| label: ",
  "",
  qmd_lines[startsWith(qmd_lines, "#| label: fig-h08-")],
  fixed = TRUE
)
expected_tables <- c(
  "tbl-h08-metrics",
  "tbl-h08-formulas",
  "tbl-h08-families",
  "tbl-h08-primary-samples",
  "tbl-h08-near-eye-results",
  "tbl-h08-near-eye-predictions",
  "tbl-h08-chest-results",
  "tbl-h08-interactions",
  "tbl-h08-paired-placement",
  "tbl-h08-response-gate",
  "tbl-h08-flagged-diagnostics",
  "tbl-h08-site-influence",
  "tbl-h08-gap-common-sample",
  "tbl-h08-photoperiod-participant-summary",
  "tbl-h08-metric-definition-sensitivities"
)
expected_figures <- c(
  "fig-h08-near-eye-effects",
  "fig-h08-chest-effects",
  "fig-h08-paired-placement",
  "fig-h08-model-adequacy",
  "fig-h08-gap-common-sample"
)
assert_true(
  identical(table_endpoints, expected_tables),
  "H08 result table endpoints or order changed"
)
assert_true(
  identical(figure_endpoints, expected_figures),
  "H08 result figure endpoints or order changed"
)

calls <- executable_r_call_names(qmd_lines)
forbidden_calls <- c(
  "lme4::lmer",
  "glmmTMB::glmmTMB",
  "stats::lm",
  "stats::glm",
  "stats::predict",
  "predict",
  "stats::simulate",
  "simulate",
  "boot::boot",
  "boot",
  "p.adjust",
  "stats::p.adjust",
  "saveRDS",
  "write.csv",
  "readr::write_csv"
)
assert_true(
  length(intersect(calls, forbidden_calls)) == 0L,
  paste(
    "H08 result source contains a prohibited analytical or artifact call:",
    paste(intersect(calls, forbidden_calls), collapse = ", ")
  )
)

markdown_matches <- regmatches(
  qmd_text,
  gregexpr("\\[[^]]*\\]\\(([^)]+)\\)", qmd_text, perl = TRUE)
)[[1L]]
targets <- sub("^.*\\]\\(([^)]+)\\)$", "\\1", markdown_matches, perl = TRUE)
expected_targets <- c(
  "../preparation/04_metric_derivation.qmd",
  "../preparation/06_model_ready_datasets.qmd",
  "../../audit/hypotheses/H08/H08_analysis_preparation.qmd",
  "../preregistration_deviations.qmd#dev-035",
  "../preregistration_deviations.qmd#dev-036",
  "../../artifacts/06_model_data/H08/H08_model_frame_by_site.csv",
  "../../artifacts/06_model_data/H08/H08_model_frame_index.csv",
  "../../artifacts/08_diagnostics/H08/H08_model_diagnostics.csv",
  "../../artifacts/08_diagnostics/H08/H08_participant_influence_screen.csv",
  "../../artifacts/09_tables/H08/H08_exactly_identified_longest_period_sensitivity.csv",
  "../../artifacts/09_tables/H08/H08_gap_timing_unaware_sensitivity.csv",
  "../../artifacts/09_tables/H08/H08_metric011_bh_recalculation.csv",
  "../../artifacts/09_tables/H08/H08_metric011_result_comparison.csv",
  "../../artifacts/09_tables/H08/H08_model_results_master.csv",
  "../../artifacts/09_tables/H08/H08_observed_dose_sensitivity.csv",
  "../../artifacts/09_tables/H08/H08_participant_summary_sensitivity.csv",
  "../../artifacts/09_tables/H08/H08_photoperiod_sensitivity.csv",
  "../../artifacts/09_tables/H08/H08_site_specific_slopes.csv",
  "../../artifacts/11_source_data/H08/H08_chest_effects_data.csv",
  "../../artifacts/11_source_data/H08/H08_gap_common_sample_effects_data.csv",
  "../../artifacts/11_source_data/H08/H08_near_eye_effects_data.csv",
  "../../artifacts/11_source_data/H08/H08_near_eye_model_adequacy_data.csv",
  "../../artifacts/11_source_data/H08/H08_paired_placement_effects_data.csv",
  "../../artifacts/12_manifests/H08/H08_figure_manifest.csv",
  "../../artifacts/12_manifests/H08/H08_metric011_reconciliation.csv",
  "../../audit/decisions/l10_numerical_zero_normalization.md"
)
assert_true(
  identical(sort(unique(targets)), sort(expected_targets)),
  "H08 result reader-link set changed"
)
assert_true(
  !any(grepl("^(file:|/|[A-Za-z]+://)", targets)) &&
    !any(grepl("[.]html($|#)", targets)) &&
    !any(grepl("_build", targets, fixed = TRUE)),
  "H08 result contains a forbidden reader-page target"
)

for (target in unique(targets)) {
  file_target <- sub("#.*$", "", target)
  anchor <- if (grepl("#", target, fixed = TRUE)) {
    sub("^[^#]*#", "", target)
  } else {
    ""
  }
  resolved <- file.path(dirname(qmd_path), file_target)
  assert_true(
    file.exists(resolved),
    sprintf("H08 link target is missing: %s", target)
  )
  if (nzchar(anchor)) {
    target_text <- paste(readLines(resolved, warn = FALSE), collapse = "\n")
    assert_true(
      grepl(sprintf("{#%s}", anchor), target_text, fixed = TRUE),
      sprintf("H08 link anchor is missing: %s", target)
    )
  }
}
assert_true(
  sum(grepl("DEV-035", qmd_lines, fixed = TRUE)) == 1L &&
    sum(grepl("DEV-036", qmd_lines, fixed = TRUE)) == 1L &&
    !grepl("DOC-001", qmd_text, fixed = TRUE),
  "H08 deviation-link contract changed"
)

expected_formulas <- c(
  "response_value ~ site + (1 | site:Id)",
  "response_value ~ site + VLSQ8_c + (1 | site:Id)",
  "response_value ~ site * VLSQ8_c + (1 | site:Id)",
  "response_value ~ site + photoperiod_c + (1 | site:Id)",
  paste0(
    "response_value ~ site + photoperiod_c + VLSQ8_c + ",
    "(1 | site:Id)"
  ),
  paste0(
    "response_value ~ site * VLSQ8_c + photoperiod_c + ",
    "(1 | site:Id)"
  ),
  "participant_response ~ site",
  "participant_response ~ site + VLSQ8_c",
  "participant_response ~ site * VLSQ8_c"
)
assert_true(
  all(vapply(expected_formulas, grepl, logical(1), x = qmd_text, fixed = TRUE)),
  "An accepted H08 formula literal is missing"
)
required_source_phrases <- c(
  "Answer in brief",
  "Visual Light Sensitivity Questionnaire (VLSQ-8)",
  "False-discovery-rate (FDR) adjustment",
  "difference in hours",
  "ratios and percentage changes",
  "same participants and participant-days",
  "none of the nine associations retained FDR-adjusted support"
)
assert_true(
  all(vapply(
    required_source_phrases,
    grepl,
    logical(1),
    x = qmd_text_normalized,
    fixed = TRUE
  )),
  "An accepted H08 reader phrase is missing"
)

master <- read.csv(
  file.path(root, "artifacts/09_tables/H08/H08_model_results_master.csv"),
  check.names = FALSE
)
families <- read.csv(
  file.path(root, "artifacts/09_tables/H08/H08_family_audit.csv"),
  check.names = FALSE
)
near <- master[master$run_id == "main__glasses__all_available", , drop = FALSE]
chest <- master[master$run_id == "main__chest__all_available", , drop = FALSE]
assert_true(
  nrow(near) == 9L && nrow(chest) == 9L,
  "H08 primary result rows changed"
)
assert_true(
  nrow(families) == 8L &&
    all(families$complete_nine_member_family) &&
    sum(families$adjusted_significant_n) == 0L,
  "H08 complete FDR-family disposition changed"
)
near_dose <- near[near$metric_id == "dose_time_sensitive_corrected_medi", ]
assert_true(
  nrow(near_dose) == 1L &&
    isTRUE(all.equal(near_dose$estimate_practical_per_sd, 0.84576049319764)) &&
    isTRUE(all.equal(near_dose$conf_low_practical_per_sd, 0.715965149670316)) &&
    isTRUE(all.equal(
      near_dose$conf_high_practical_per_sd,
      0.999086075884138
    )) &&
    isTRUE(all.equal(near_dose$average_p_raw, 0.0510410963693195)) &&
    isTRUE(all.equal(near_dose$average_p_adjusted, 0.160039116372493)),
  "H08 accepted near-eye dose estimate changed"
)

figure_qa <- read.csv(
  file.path(root, "artifacts/12_manifests/H08/H08_figure_physical_size_qa.csv"),
  check.names = FALSE
)
result_figure_qa <- figure_qa[
  figure_qa$figure_id %in% expected_figures,
]
assert_true(
  nrow(result_figure_qa) == 5L &&
    all(result_figure_qa$effective_final_essential_text_pt >= 7) &&
    all(result_figure_qa$status == "PASS"),
  "H08 result figure physical-size contract changed"
)

stage3_manifest <- read.csv(
  file.path(root, "artifacts/12_manifests/H08/H08_stage3_artifacts.csv"),
  check.names = FALSE
)
stage3_files <- file.path(root, stage3_manifest$path)
stage3_exists <- file.exists(stage3_files)
stage3_sha <- rep(NA_character_, nrow(stage3_manifest))
stage3_bytes <- rep(NA_real_, nrow(stage3_manifest))
stage3_sha[stage3_exists] <- vapply(
  stage3_files[stage3_exists],
  sha256_file,
  character(1)
)
stage3_bytes[stage3_exists] <- unname(
  file.info(stage3_files[stage3_exists])$size
)
stage3_exact <- stage3_exists &
  stage3_sha == stage3_manifest$sha256 &
  stage3_bytes == stage3_manifest$bytes
expected_historical_transitions <- c(
  "notebooks/hypotheses/H08.qmd",
  "_quarto-nathealth.yml"
)
assert_true(
  nrow(stage3_manifest) == 102L &&
    sum(stage3_exact) == 100L &&
    identical(
      sort(stage3_manifest$path[!stage3_exact]),
      sort(expected_historical_transitions)
    ),
  "H08 historical Stage 3 manifest transition set changed"
)

reader_test_text <- paste(
  readLines(file.path(
    root,
    "tests/hypotheses/H08/test_h08_stage3_reader_report.R"
  )),
  collapse = "\n"
)
assert_true(
  grepl("Results in brief", reader_test_text, fixed = TRUE) &&
    grepl("!grepl(\"Answer in brief\"", reader_test_text, fixed = TRUE) &&
    grepl("length(gt_tables) == 14L", reader_test_text, fixed = TRUE) &&
    grepl("BH-adjusted", reader_test_text, fixed = TRUE) &&
    grepl("Answer in brief", qmd_text, fixed = TRUE) &&
    length(table_endpoints) == 15L,
  "H08 historical reader-test classification changed"
)

profile_lines <- readLines(
  file.path(root, "_quarto-nathealth.yml"),
  warn = FALSE
)
assert_adjacent_profile_entries(
  profile_lines,
  "notebooks/hypotheses/H08.qmd",
  "audit/hypotheses/H08/H08_analysis_preparation.qmd"
)

phase4 <- read.csv(
  file.path(root, "audit/report_harmonization/phase4_corpus_manifest.csv"),
  check.names = FALSE
)
h08_phase4 <- phase4[phase4$source == "notebooks/hypotheses/H08.qmd", ]
assert_true(
  nrow(h08_phase4) == 1L &&
    identical(h08_phase4$source_sha256[[1]], sha256_file(qmd_path)) &&
    identical(
      h08_phase4$html_sha256[[1]],
      sha256_file(file.path(
        root,
        "_build/nathealth/notebooks/hypotheses/H08.html"
      ))
    ),
  "H08 phase-4 corpus row changed before render"
)

matrix <- read.csv(
  file.path(root, "audit/report_harmonization/coordination_matrix.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
h08_row <- matrix[matrix$logical_order == 10L, , drop = FALSE]
assert_true(nrow(h08_row) == 1L, "Coordination matrix has no unique H08 row")
assert_true(
  identical(
    h08_row$harmonization_review_status[[1]],
    "source_only_adjustment_native_gt_formula_table_and_exact_deviation_links_accepted"
  ),
  "H08 source-acceptance status changed"
)

build_root <- file.path(root, "_build/nathealth")
build_entries <- list.files(
  build_root,
  recursive = TRUE,
  all.files = TRUE,
  full.names = TRUE,
  include.dirs = TRUE,
  no.. = TRUE
)
assert_true(
  !any(nzchar(Sys.readlink(build_entries))),
  "The Nature Health build contains a symlink"
)

quarto_version <- system2("quarto", "--version", stdout = TRUE, stderr = TRUE)
assert_true(
  length(quarto_version) >= 1L &&
    identical(trimws(quarto_version[[1L]]), "1.9.37"),
  "Quarto 1.9.37 required"
)

cat(sprintf(
  paste0(
    "H08_RESULT_REPORT018_RELEASE=PASS pins=31/31 chunks=22 ",
    "tables=15 figures=5 links=%d deviations=2 historical_manifest=100/102 ",
    "reader_test=DEFERRED_HISTORICAL forbidden_calls=0 build_symlinks=0 ",
    "R=%s quarto=%s\n"
  ),
  length(unique(targets)),
  as.character(getRversion()),
  trimws(quarto_version[[1L]])
))
