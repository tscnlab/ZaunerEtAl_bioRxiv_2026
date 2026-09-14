#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

required_packages <- c("digest")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing required R packages: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H09 result release requires R 4.6.1", call. = FALSE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

checks <- data.frame(
  check = character(),
  observed = character(),
  expected = character(),
  status = character()
)

add_check <- function(check, observed, expected, pass) {
  checks <<- rbind(
    checks,
    data.frame(
      check = check,
      observed = as.character(observed),
      expected = as.character(expected),
      status = if (isTRUE(pass)) "PASS" else "FAIL"
    )
  )
}

pins_path <- file.path(
  root,
  "audit/report_harmonization/report018_h09_result_release_pins.csv"
)
pins <- read.csv(pins_path, check.names = FALSE)
expected_pin_columns <- c("role", "relative_path", "sha256", "bytes")
add_check(
  "pin columns",
  paste(names(pins), collapse = "|"),
  paste(expected_pin_columns, collapse = "|"),
  identical(names(pins), expected_pin_columns)
)
add_check("pin rows", nrow(pins), 42L, nrow(pins) == 42L)
add_check(
  "pin roles unique",
  length(unique(pins$role)),
  42L,
  !anyDuplicated(pins$role)
)
add_check(
  "pin paths unique",
  length(unique(pins$relative_path)),
  42L,
  !anyDuplicated(pins$relative_path)
)

pin_files <- file.path(root, pins$relative_path)
pin_exists <- file.exists(pin_files) & !dir.exists(pin_files)
pin_sha <- rep(NA_character_, nrow(pins))
pin_bytes <- rep(NA_real_, nrow(pins))
pin_sha[pin_exists] <- vapply(
  pin_files[pin_exists],
  sha256_file,
  character(1)
)
pin_bytes[pin_exists] <- unname(file.info(pin_files[pin_exists])$size)
pin_exact <- pin_exists &
  pin_sha == pins$sha256 &
  pin_bytes == pins$bytes
add_check(
  "pin identities",
  paste0(sum(pin_exact), "/", nrow(pins)),
  "42/42",
  all(pin_exact)
)

preceding_manifest_path <- file.path(
  root,
  "audit/report_harmonization/",
  "report018_h08_companion_independent_acceptance_manifest.csv"
)
preceding_manifest <- read.csv(preceding_manifest_path, check.names = FALSE)
preceding_files <- file.path(root, preceding_manifest$path)
preceding_exact <- file.exists(preceding_files) &
  vapply(
    preceding_files,
    sha256_file,
    character(1)
  ) ==
    preceding_manifest$sha256 &
  unname(file.info(preceding_files)$size) == preceding_manifest$bytes
add_check(
  "preceding H08 acceptance manifest",
  paste0(sum(preceding_exact), "/", nrow(preceding_manifest)),
  "30/30",
  nrow(preceding_manifest) == 30L &&
    !anyDuplicated(preceding_manifest$path) &&
    !"audit/report_harmonization/report018_h08_companion_independent_acceptance_manifest.csv" %in%
      preceding_manifest$path &&
    all(preceding_exact)
)

source(file.path(
  root,
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
))

qmd_path <- file.path(root, "notebooks/hypotheses/H09.qmd")
companion_path <- file.path(
  root,
  "audit/hypotheses/H09/H09_analysis_preparation.qmd"
)
qmd_lines <- readLines(qmd_path, warn = FALSE)
qmd_text <- paste(qmd_lines, collapse = "\n")
qmd_text_normalized <- gsub("[[:space:]]+", " ", qmd_text)

chunks <- extract_executable_r_chunks(qmd_lines)
chunk_parse <- vapply(
  chunks,
  function(chunk) {
    tryCatch(
      {
        parse(text = chunk, keep.source = FALSE)
        TRUE
      },
      error = function(error) FALSE
    )
  },
  logical(1)
)
add_check(
  "parseable R chunks",
  paste0(sum(chunk_parse), "/", length(chunks)),
  "17/17",
  length(chunks) == 17L && all(chunk_parse)
)

table_endpoints <- sub(
  "#| label: ",
  "",
  qmd_lines[startsWith(qmd_lines, "#| label: tbl-h09-")],
  fixed = TRUE
)
figure_endpoints <- sub(
  "#| label: ",
  "",
  qmd_lines[startsWith(qmd_lines, "#| label: fig-h09-")],
  fixed = TRUE
)
expected_tables <- c(
  "tbl-h09-metrics",
  "tbl-h09-formulas",
  "tbl-h09-primary-samples",
  "tbl-h09-near-eye-results",
  "tbl-h09-chest-results",
  "tbl-h09-paired-placement",
  "tbl-h09-interactions",
  "tbl-h09-qualified-diagnostics",
  "tbl-h09-gap-sensitivity",
  "tbl-h09-sensitivity-summary",
  "tbl-h09-mean-timing-sensitivity"
)
expected_figures <- c(
  "fig-h09-primary-effects",
  "fig-h09-paired-placement",
  "fig-h09-near-eye-diagnostics",
  "fig-h09-chest-diagnostics"
)
add_check(
  "table endpoints and order",
  paste(table_endpoints, collapse = "|"),
  paste(expected_tables, collapse = "|"),
  identical(table_endpoints, expected_tables)
)
add_check(
  "figure endpoints and order",
  paste(figure_endpoints, collapse = "|"),
  paste(expected_figures, collapse = "|"),
  identical(figure_endpoints, expected_figures)
)

calls <- executable_r_call_names(qmd_lines)
forbidden_calls <- c(
  "lme4::lmer",
  "glmmTMB::glmmTMB",
  "nlme::lme",
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
prohibited <- intersect(calls, forbidden_calls)
add_check(
  "prohibited scientific or artifact calls",
  paste(prohibited, collapse = "|"),
  "none",
  length(prohibited) == 0L
)

normalized_markdown <- gsub("[\r\n]+", " ", qmd_text)
markdown_matches <- regmatches(
  normalized_markdown,
  gregexpr(
    "\\[[^]]*\\]\\(([^)]+)\\)",
    normalized_markdown,
    perl = TRUE
  )
)[[1L]]
targets <- sub("^.*\\]\\(", "", markdown_matches, perl = TRUE)
targets <- sub("\\)$", "", targets, perl = TRUE)
expected_targets <- c(
  "../preparation/04_metric_derivation.qmd",
  "../preparation/06_model_ready_datasets.qmd",
  "../../audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "../preregistration_deviations.qmd#dev-037",
  "../preregistration_deviations.qmd#dev-038",
  "../preregistration_deviations.qmd#dev-039",
  "../../artifacts/08_diagnostics/H09/H09_diagnostic_assessment_registry.csv",
  "../../artifacts/08_diagnostics/H09/H09_diagnostic_author_adjudication.csv",
  "../../artifacts/08_diagnostics/H09/H09_leave_one_site_out_summary.csv",
  "../../artifacts/08_diagnostics/H09/H09_participant_influence_summary.csv",
  "../../artifacts/09_tables/H09/H09_ar1_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_fifth_outcome_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_gap_timing_unaware_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_l10_cut_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_model_results_master.csv",
  "../../artifacts/09_tables/H09/H09_participant_summary_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_photoperiod_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_site_specific_slopes.csv",
  "../../artifacts/11_source_data/H09/H09_paired_placement_effects_data.csv",
  "../../artifacts/11_source_data/H09/H09_primary_effects_data.csv",
  "../../artifacts/12_manifests/H09/H09_figure_manifest.csv"
)
add_check(
  "reader-link multiset size",
  paste(length(targets), length(unique(targets)), sep = "/"),
  "23/21",
  length(targets) == 23L && length(unique(targets)) == 21L
)
add_check(
  "reader-link set",
  paste(sort(unique(targets)), collapse = "|"),
  paste(sort(expected_targets), collapse = "|"),
  identical(sort(unique(targets)), sort(expected_targets))
)
add_check(
  "reader-link path safety",
  sum(
    grepl("^(file:|/|[A-Za-z]+://)", targets) |
      grepl("[.]html($|#)", targets) |
      grepl("_build", targets, fixed = TRUE)
  ),
  0L,
  !any(grepl("^(file:|/|[A-Za-z]+://)", targets)) &&
    !any(grepl("[.]html($|#)", targets)) &&
    !any(grepl("_build", targets, fixed = TRUE))
)

link_checks <- vapply(
  unique(targets),
  function(target) {
    file_target <- sub("#.*$", "", target)
    anchor <- if (grepl("#", target, fixed = TRUE)) {
      sub("^[^#]*#", "", target)
    } else {
      ""
    }
    resolved <- file.path(dirname(qmd_path), file_target)
    if (!file.exists(resolved)) {
      return(FALSE)
    }
    if (!nzchar(anchor)) {
      return(TRUE)
    }
    target_text <- paste(readLines(resolved, warn = FALSE), collapse = "\n")
    grepl(sprintf("{#%s}", anchor), target_text, fixed = TRUE)
  },
  logical(1)
)
add_check(
  "reader-link target and fragment resolution",
  paste0(sum(link_checks), "/", length(link_checks)),
  "21/21",
  all(link_checks)
)
add_check(
  "deviation-link contract",
  paste(
    sum(grepl("DEV-037", qmd_lines, fixed = TRUE)),
    sum(grepl("DEV-038", qmd_lines, fixed = TRUE)),
    sum(grepl("DEV-039", qmd_lines, fixed = TRUE)),
    grepl("IMP-009", qmd_text, fixed = TRUE),
    sep = "/"
  ),
  "1/1/1/FALSE",
  sum(grepl("DEV-037", qmd_lines, fixed = TRUE)) == 1L &&
    sum(grepl("DEV-038", qmd_lines, fixed = TRUE)) == 1L &&
    sum(grepl("DEV-039", qmd_lines, fixed = TRUE)) == 1L &&
    !grepl("IMP-009", qmd_text, fixed = TRUE)
)

expected_formulas <- c(
  "timing_hour ~ site + (1 | site:Id)",
  "timing_hour ~ site + mctq_hour_centered + (1 | site:Id)",
  "timing_hour ~ site * mctq_hour_centered + (1 | site:Id)",
  "timing_hour ~ site + meq_10_centered + (1 | site:Id)",
  "timing_hour ~ site * meq_10_centered + (1 | site:Id)"
)
formula_present <- vapply(
  expected_formulas,
  grepl,
  logical(1),
  x = qmd_text,
  fixed = TRUE
)
add_check(
  "exact formula literals",
  paste0(sum(formula_present), "/", length(formula_present)),
  "5/5",
  all(formula_present)
)

required_phrases <- c(
  "Answer in brief",
  "Munich Chronotype Questionnaire corrected midsleep on free days (MCTQ MSFsc)",
  "Morningness–Eveningness Questionnaire (MEQ)",
  "false-discovery-rate (FDR)",
  "participant-day",
  "random effect",
  "not an equivalence",
  "gap-timing-unaware dataset",
  "50%-per-hour",
  "80%-per-day",
  "time-sensitive primary dataset",
  "does not establish that chronotype causes"
)
phrase_present <- vapply(
  required_phrases,
  grepl,
  logical(1),
  x = qmd_text_normalized,
  fixed = TRUE
)
add_check(
  "accepted source phrases",
  paste0(sum(phrase_present), "/", length(phrase_present)),
  "12/12",
  all(phrase_present)
)
add_check(
  "reader-facing BH abbreviation absent",
  sum(grepl("BH", qmd_lines, fixed = TRUE)),
  0L,
  !grepl("BH", qmd_text, fixed = TRUE)
)

master <- read.csv(
  file.path(root, "artifacts/09_tables/H09/H09_model_results_master.csv"),
  check.names = FALSE
)
families <- read.csv(
  file.path(root, "artifacts/09_tables/H09/H09_family_audit.csv"),
  check.names = FALSE
)
primary <- master[
  master$data_scenario_id == "primary" &
    master$sample_scenario == "all_available" &
    master$primary_family_member,
  ,
  drop = FALSE
]
near <- primary[primary$placement == "glasses", , drop = FALSE]
chest <- primary[primary$placement == "chest", , drop = FALSE]
primary_families <- families[
  families$run_id %in%
    c("primary__glasses__all_available", "primary__chest__all_available"),
  ,
  drop = FALSE
]
scientific_contract <- nrow(primary) == 20L &&
  nrow(near) == 10L &&
  nrow(chest) == 10L &&
  nrow(primary_families) == 8L &&
  all(primary_families$planned_members == 5L) &&
  all(primary_families$complete_registered_family) &&
  all(primary_families$independent_recalculation_matches) &&
  sum(near$main_adjusted_significant) == 6L &&
  sum(chest$main_adjusted_significant) == 4L &&
  !any(primary$interaction_adjusted_significant)
add_check(
  "primary scientific and multiplicity contract",
  paste(
    nrow(primary),
    nrow(primary_families),
    sum(near$main_adjusted_significant),
    sum(chest$main_adjusted_significant),
    sum(primary$interaction_adjusted_significant),
    sep = "/"
  ),
  "20/8/6/4/0",
  scientific_contract
)

near_mctq <- near[
  near$metric_id == "first_timing_above_250" &
    near$instrument_id == "MCTQ",
  ,
  drop = FALSE
]
near_meq <- near[
  near$metric_id == "first_timing_above_250" &
    near$instrument_id == "MEQ",
  ,
  drop = FALSE
]
key_estimates_pass <- nrow(near_mctq) == 1L &&
  nrow(near_meq) == 1L &&
  isTRUE(all.equal(near_mctq$estimate, 0.381236542890041, tolerance = 1e-12)) &&
  isTRUE(all.equal(near_mctq$conf_low, 0.146253946350557, tolerance = 1e-12)) &&
  isTRUE(all.equal(
    near_mctq$conf_high,
    0.616219139429526,
    tolerance = 1e-12
  )) &&
  isTRUE(all.equal(
    near_mctq$main_p_adjusted,
    0.00298827104154086,
    tolerance = 1e-12
  )) &&
  isTRUE(all.equal(near_meq$estimate, -0.443907364409369, tolerance = 1e-12)) &&
  isTRUE(all.equal(near_meq$conf_low, -0.698616503785482, tolerance = 1e-12)) &&
  isTRUE(all.equal(
    near_meq$conf_high,
    -0.189198225033256,
    tolerance = 1e-12
  )) &&
  isTRUE(all.equal(
    near_meq$main_p_adjusted,
    0.00130345909142947,
    tolerance = 1e-12
  ))
add_check(
  "accepted key estimates",
  paste(
    near_mctq$estimate,
    near_mctq$main_p_adjusted,
    near_meq$estimate,
    near_meq$main_p_adjusted,
    sep = "/"
  ),
  "0.381236542890041/0.00298827104154086/-0.443907364409369/0.00130345909142947",
  key_estimates_pass
)

figure_manifest <- read.csv(
  file.path(root, "artifacts/12_manifests/H09/H09_figure_manifest.csv"),
  check.names = FALSE
)
result_figure_ids <- c(
  "primary_effects",
  "paired_placement_effects",
  "diagnostics_near_eye",
  "diagnostics_chest"
)
result_figures <- figure_manifest[
  figure_manifest$figure_id %in% result_figure_ids,
  ,
  drop = FALSE
]
figure_files <- file.path(root, result_figures$figure_path)
source_files <- file.path(root, result_figures$source_data_path)
figure_contract <- nrow(result_figures) == 4L &&
  all(file.exists(figure_files)) &&
  all(file.exists(source_files)) &&
  all(result_figures$intended_display_width_mm == 170) &&
  all(grepl("^PASS", result_figures$visual_qa_status))
add_check(
  "stored figure and paired-source contract",
  paste(
    nrow(result_figures),
    sum(file.exists(figure_files)),
    sum(file.exists(source_files)),
    sep = "/"
  ),
  "4/4/4",
  figure_contract
)
add_check(
  "known typography range retained for live QA",
  paste(range(result_figures$effective_final_text_pt), collapse = "/"),
  "5.099363/6.692913 and mandatory fresh final-size inspection",
  isTRUE(all.equal(
    range(result_figures$effective_final_text_pt),
    c(5.099363, 6.692913),
    tolerance = 1e-6
  ))
)

stage3_manifest <- read.csv(
  file.path(root, "artifacts/12_manifests/H09/H09_stage3_artifacts.csv"),
  check.names = FALSE
)
stage3_files <- file.path(root, stage3_manifest$path)
stage3_exists <- file.exists(stage3_files) & !dir.exists(stage3_files)
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
  "audit/handoffs/H09_shared_change_request.md",
  "audit/handoffs/H09_worker_handoff.md",
  "audit/hypotheses/H09/H09_stage1_gate_and_stage2_transition.md",
  "audit/decisions/figure_readability_and_layout.md",
  "artifacts/06_model_data/H09/H09_base_bundle_audit.csv",
  "artifacts/06_model_data/H09/H09_input_audit.csv",
  "config/metric_display_registry.csv",
  "notebooks/hypotheses/H09.qmd",
  "scripts/hypotheses/H09/h09_contract.R",
  "scripts/hypotheses/H09/run_h09_stage2.R",
  "_quarto-nathealth.yml"
)
add_check(
  "historical Stage 3 manifest transitions",
  paste0(sum(stage3_exact), "/", nrow(stage3_manifest)),
  "97/108 with exact 11-path accepted transition set",
  nrow(stage3_manifest) == 108L &&
    sum(stage3_exact) == 97L &&
    identical(
      sort(stage3_manifest$path[!stage3_exact]),
      sort(expected_historical_transitions)
    )
)

reader_test_text <- paste(
  readLines(
    file.path(root, "tests/hypotheses/H09/test_h09_stage3_reader_report.R"),
    warn = FALSE
  ),
  collapse = "\n"
)
add_check(
  "historical reader-test classification",
  paste(
    grepl("BH-adjusted", reader_test_text, fixed = TRUE),
    grepl("FDR-adjusted", qmd_text, fixed = TRUE),
    sep = "/"
  ),
  "TRUE/TRUE and test deferred",
  grepl("BH-adjusted", reader_test_text, fixed = TRUE) &&
    grepl("FDR-adjusted", qmd_text, fixed = TRUE)
)

profile_lines <- readLines(
  file.path(root, "_quarto-nathealth.yml"),
  warn = FALSE
)
profile_check <- tryCatch(
  {
    assert_adjacent_profile_entries(
      profile_lines,
      "notebooks/hypotheses/H09.qmd",
      "audit/hypotheses/H09/H09_analysis_preparation.qmd"
    )
    TRUE
  },
  error = function(error) FALSE
)
add_check("profile adjacency", profile_check, TRUE, profile_check)

phase4 <- read.csv(
  file.path(root, "audit/report_harmonization/phase4_corpus_manifest.csv"),
  check.names = FALSE
)
h09_phase4 <- phase4[phase4$source == "notebooks/hypotheses/H09.qmd", ]
phase4_pass <- nrow(h09_phase4) == 1L &&
  h09_phase4$source_sha256[[1]] == sha256_file(qmd_path) &&
  h09_phase4$html_sha256[[1]] ==
    sha256_file(file.path(
      root,
      "_build/nathealth/notebooks/hypotheses/H09.html"
    ))
add_check(
  "phase-4 current H09 row",
  paste(
    h09_phase4$source_sha256[[1]],
    h09_phase4$html_sha256[[1]],
    sep = "/"
  ),
  "current source/current pre-render HTML",
  phase4_pass
)

matrix <- read.csv(
  file.path(root, "audit/report_harmonization/coordination_matrix.csv"),
  check.names = FALSE
)
h09_row <- matrix[matrix$logical_order == 11L, , drop = FALSE]
matrix_pass <- nrow(h09_row) == 1L &&
  h09_row$current_task_status_2026_08_12[[1]] == "idle" &&
  h09_row$harmonization_review_status[[1]] ==
    "source_only_adjustment_and_exact_deviation_links_accepted"
add_check(
  "H09 coordination safe point",
  paste(
    h09_row$current_task_status_2026_08_12[[1]],
    h09_row$harmonization_review_status[[1]],
    sep = "/"
  ),
  "idle/source_only_adjustment_and_exact_deviation_links_accepted",
  matrix_pass
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
build_symlinks <- nzchar(Sys.readlink(build_entries))
add_check(
  "build symlinks",
  sum(build_symlinks),
  0L,
  !any(build_symlinks)
)

quarto_version <- system2("quarto", "--version", stdout = TRUE, stderr = TRUE)
quarto_version <- trimws(quarto_version[[1L]])
add_check(
  "Quarto version",
  quarto_version,
  "1.9.37",
  identical(quarto_version, "1.9.37")
)

checks$r_version <- as.character(getRversion())
checks$digest_version <- as.character(utils::packageVersion("digest"))
checks$quarto_version <- quarto_version

output_path <- file.path(
  root,
  "audit/report_harmonization/report018_h09_result_release_verification.csv"
)
write.csv(checks, output_path, row.names = FALSE, na = "")

failures <- checks$status != "PASS"
if (any(failures)) {
  print(checks[failures, , drop = FALSE])
  stop("H09 result release verification failed", call. = FALSE)
}

cat(sprintf(
  paste0(
    "H09_RESULT_REPORT018_RELEASE=PASS checks=%d/%d pins=42/42 ",
    "preceding=30/30 chunks=17 tables=11 figures=4 links=23/21 ",
    "deviations=3 historical_manifest=97/108+11 ",
    "reader_test=DEFERRED_HISTORICAL forbidden_calls=0 ",
    "build_symlinks=0 R=%s quarto=%s\n"
  ),
  nrow(checks),
  nrow(checks),
  as.character(getRversion()),
  quarto_version
))
