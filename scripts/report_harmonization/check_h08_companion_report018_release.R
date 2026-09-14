#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
pins_path <- file.path(
  root,
  "audit/report_harmonization/report018_h08_companion_release_pins.csv"
)
verification_path <- file.path(
  root,
  "audit/report_harmonization/report018_h08_companion_release_verification.csv"
)
qmd_rel <- "audit/hypotheses/H08/H08_analysis_preparation.qmd"
qmd_path <- file.path(root, qmd_rel)
build_qmd_rel <- paste0(
  "_build/nathealth/audit/hypotheses/H08/",
  "H08_analysis_preparation.qmd"
)
build_qmd_path <- file.path(root, build_qmd_rel)
html_rel <- paste0(
  "_build/nathealth/audit/hypotheses/H08/",
  "H08_analysis_preparation.html"
)
html_path <- file.path(root, html_rel)
manifest_rel <- "artifacts/12_manifests/H08/H08_preparation_report_manifest.csv"
manifest_path <- file.path(root, manifest_rel)
helper_rel <- "scripts/hypotheses/H08/build_h08_preparation_report_manifest.R"
helper_path <- file.path(root, helper_rel)

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

source(file.path(
  root,
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
))

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

file_bytes <- function(path) {
  unname(file.info(path)$size)
}

read_raw_file <- function(path) {
  readBin(path, what = "raw", n = file_bytes(path))
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

pins <- read.csv(pins_path, check.names = FALSE)
pin_files <- file.path(root, pins$relative_path)
pin_exists <- file.exists(pin_files) & !dir.exists(pin_files)
pin_sha <- rep(NA_character_, nrow(pins))
pin_bytes <- rep(NA_real_, nrow(pins))
pin_sha[pin_exists] <- unname(vapply(
  pin_files[pin_exists],
  sha256_file,
  character(1)
))
pin_bytes[pin_exists] <- unname(vapply(
  pin_files[pin_exists],
  file_bytes,
  numeric(1)
))
pin_exact <- pin_exists &
  pin_sha == pins$sha256 &
  pin_bytes == as.numeric(pins$bytes)
add_check("release pin rows", nrow(pins), 34L, nrow(pins) == 34L)
add_check(
  "release pin paths unique",
  length(unique(pins$relative_path)),
  nrow(pins),
  !anyDuplicated(pins$relative_path)
)
add_check(
  "release pin set non-circular",
  sum(pins$relative_path == basename(pins_path)),
  0L,
  !any(
    pins$relative_path ==
      "audit/report_harmonization/report018_h08_companion_release_pins.csv"
  )
)
add_check(
  "release pin identities",
  sum(pin_exact),
  nrow(pins),
  all(pin_exact)
)

result_acceptance_manifest <- read.csv(
  file.path(
    root,
    "audit/report_harmonization/report018_h08_result_independent_acceptance_manifest.csv"
  ),
  check.names = FALSE
)
result_acceptance_files <- file.path(root, result_acceptance_manifest$path)
result_acceptance_exact <- file.exists(result_acceptance_files) &
  !dir.exists(result_acceptance_files) &
  unname(vapply(
    result_acceptance_files,
    sha256_file,
    character(1)
  )) ==
    result_acceptance_manifest$sha256 &
  unname(file.info(result_acceptance_files)$size) ==
    as.numeric(result_acceptance_manifest$bytes)
add_check(
  "result acceptance manifest",
  paste0(sum(result_acceptance_exact), "/", nrow(result_acceptance_manifest)),
  "31/31",
  nrow(result_acceptance_manifest) == 31L &&
    !anyDuplicated(result_acceptance_manifest$path) &&
    !any(
      result_acceptance_manifest$path ==
        "audit/report_harmonization/report018_h08_result_independent_acceptance_manifest.csv"
    ) &&
    all(result_acceptance_exact)
)

qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
qmd_text <- paste(qmd_lines, collapse = "\n")
qmd_compact <- gsub("[[:space:]]+", " ", qmd_text)
chunks <- extract_executable_r_chunks(qmd_lines)
chunk_parse <- vapply(
  chunks,
  function(chunk) {
    !inherits(try(parse(text = chunk), silent = TRUE), "try-error")
  },
  logical(1)
)
add_check("R chunks", length(chunks), 24L, length(chunks) == 24L)
add_check(
  "R chunk parse",
  sum(chunk_parse),
  length(chunk_parse),
  all(chunk_parse)
)

expected_tables <- c(
  "tbl-h08-prep-input-identities",
  "tbl-h08-prep-integrity-checks",
  "tbl-h08-prep-score-audit",
  "tbl-h08-prep-metric-contract",
  "tbl-h08-prep-availability",
  "tbl-h08-prep-primary-samples",
  "tbl-h08-prep-site-support",
  "tbl-h08-prep-exact-formulas",
  "tbl-h08-prep-model-settings",
  "tbl-h08-prep-family-audit",
  "tbl-h08-prep-response-gate",
  "tbl-h08-prep-site-influence",
  "tbl-h08-prep-sensitivity-map",
  "tbl-h08-prep-boundary",
  "tbl-h08-prep-metric011",
  "tbl-h08-prep-module-map",
  "tbl-h08-prep-script-map",
  "tbl-h08-prep-output-identities",
  "tbl-h08-prep-environment"
)
expected_figures <- c(
  "fig-h08-prep-vlsq-distribution",
  "fig-h08-prep-sample-support",
  "fig-h08-prep-site-range"
)
table_labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: tbl-h08-", qmd_lines, value = TRUE)
)
figure_labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: fig-h08-", qmd_lines, value = TRUE)
)
add_check(
  "table endpoint order",
  paste(table_labels, collapse = "|"),
  paste(expected_tables, collapse = "|"),
  identical(table_labels, expected_tables)
)
add_check(
  "figure endpoint order",
  paste(figure_labels, collapse = "|"),
  paste(expected_figures, collapse = "|"),
  identical(figure_labels, expected_figures)
)
mermaid_count <- sum(trimws(qmd_lines) == "flowchart TD")
add_check("top-down Mermaid", mermaid_count, 1L, mermaid_count == 1L)

calls <- executable_r_call_names(qmd_lines)
forbidden_calls <- c(
  "mgcv::gam",
  "mgcv::bam",
  "gam",
  "bam",
  "lme4::lmer",
  "lmer",
  "glmmTMB::glmmTMB",
  "glmmTMB",
  "stats::glm",
  "glm",
  "stats::predict",
  "predict",
  "stats::simulate",
  "simulate",
  "boot::boot",
  "boot",
  "h08_fit_model",
  "h08_fit_bundle",
  "h08_fit_inferential_bundle",
  "h08_model_diagnostics",
  "h08_leave_one_site_out",
  "h08_photoperiod_sensitivity",
  "h08_participant_summary_sensitivity"
)
forbidden_observed <- intersect(calls, forbidden_calls)
add_check(
  "forbidden scientific calls",
  paste(forbidden_observed, collapse = "|"),
  "none",
  length(forbidden_observed) == 0L
)

dynamic_pattern <- paste0(
  "\\.\\./\\.\\./\\.\\./notebooks/hypotheses/H08\\.qmd",
  "(?:#[A-Za-z0-9_-]+)?"
)
dynamic_matches <- gregexpr(dynamic_pattern, qmd_text, perl = TRUE)
dynamic_result_links <- regmatches(qmd_text, dynamic_matches)[[1L]]
expected_dynamic_links <- c(
  rep("../../../notebooks/hypotheses/H08.qmd", 2L),
  "../../../notebooks/hypotheses/H08.qmd#h08-preregistration-deviations"
)
add_check(
  "dynamic result links",
  paste(sort(dynamic_result_links), collapse = "|"),
  paste(sort(expected_dynamic_links), collapse = "|"),
  identical(sort(dynamic_result_links), sort(expected_dynamic_links))
)

relative_matches <- gregexpr(
  "\\]\\((\\.\\./[^)]+)\\)",
  qmd_text,
  perl = TRUE
)
relative_values <- regmatches(qmd_text, relative_matches)[[1L]]
relative_targets <- sub("^\\]\\(", "", relative_values)
relative_targets <- sub("\\)$", "", relative_targets)
relative_files <- sub("#.*$", "", relative_targets)
resolved_targets <- file.path(dirname(qmd_path), relative_files)
relative_exists <- file.exists(resolved_targets)
add_check(
  "relative reader targets resolve",
  paste0(sum(relative_exists), "/", length(relative_exists)),
  paste0(length(relative_exists), "/", length(relative_exists)),
  length(relative_exists) == 25L && all(relative_exists)
)

profile_lines <- readLines(
  file.path(root, "_quarto-nathealth.yml"),
  warn = FALSE,
  encoding = "UTF-8"
)
profile_trim <- trimws(profile_lines)
result_profile_index <- which(
  profile_trim == "- notebooks/hypotheses/H08.qmd"
)
companion_profile_index <- which(
  profile_trim == "- audit/hypotheses/H08/H08_analysis_preparation.qmd"
)
add_check(
  "profile adjacency",
  paste(result_profile_index, companion_profile_index, sep = "/"),
  "single adjacent entries",
  length(result_profile_index) == 1L &&
    length(companion_profile_index) == 1L &&
    companion_profile_index == result_profile_index + 1L
)

add_check(
  "stale build QMD",
  sha256_file(build_qmd_path),
  "source differs before helper",
  !identical(read_raw_file(qmd_path), read_raw_file(build_qmd_path))
)
add_check(
  "held companion HTML",
  paste(file_bytes(html_path), sha256_file(html_path), sep = "/"),
  paste(
    675700,
    "95f5ba0aede0ee6cf0d1b65fcdc53623d52810f8316c846cb214b4fb34a5f135",
    sep = "/"
  ),
  file_bytes(html_path) == 675700 &&
    sha256_file(html_path) ==
      "95f5ba0aede0ee6cf0d1b65fcdc53623d52810f8316c846cb214b4fb34a5f135"
)
add_check(
  "source-side HTML absent",
  file.exists(file.path(
    root,
    "audit/hypotheses/H08/H08_analysis_preparation.html"
  )),
  FALSE,
  !file.exists(file.path(
    root,
    "audit/hypotheses/H08/H08_analysis_preparation.html"
  ))
)

manifest <- read.csv(manifest_path, check.names = FALSE)
manifest_files <- file.path(root, manifest$path)
manifest_exists <- file.exists(manifest_files) & !dir.exists(manifest_files)
manifest_sha <- rep(NA_character_, nrow(manifest))
manifest_bytes <- rep(NA_real_, nrow(manifest))
manifest_sha[manifest_exists] <- unname(vapply(
  manifest_files[manifest_exists],
  sha256_file,
  character(1)
))
manifest_bytes[manifest_exists] <- unname(vapply(
  manifest_files[manifest_exists],
  file_bytes,
  numeric(1)
))
manifest_exact <- manifest_exists &
  manifest_sha == manifest$sha256 &
  manifest_bytes == as.numeric(manifest$bytes)
manifest_mismatch_paths <- manifest$path[!manifest_exact]
expected_mismatch_paths <- c(
  "audit/hypotheses/H08/H08_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H08.html",
  "notebooks/hypotheses/H08.qmd",
  "_quarto-nathealth.yml"
)
add_check(
  "current preparation manifest rows",
  nrow(manifest),
  125L,
  nrow(manifest) == 125L
)
add_check(
  "current preparation manifest uniqueness",
  length(unique(manifest$path)),
  nrow(manifest),
  !anyDuplicated(manifest$path)
)
add_check(
  "current preparation manifest exact rows",
  sum(manifest_exact),
  121L,
  sum(manifest_exact) == 121L
)
add_check(
  "current preparation manifest expected mismatches",
  paste(sort(manifest_mismatch_paths), collapse = "|"),
  paste(sort(expected_mismatch_paths), collapse = "|"),
  setequal(manifest_mismatch_paths, expected_mismatch_paths)
)

preparation_test_text <- paste(
  readLines(
    file.path(root, "tests/hypotheses/H08/test_h08_preparation_report.R"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
add_check(
  "held stale HTML assertion classification",
  paste(
    grepl(
      "../../../notebooks/hypotheses/H08.html",
      preparation_test_text,
      fixed = TRUE
    ),
    grepl("../../../notebooks/hypotheses/H08.html", qmd_text, fixed = TRUE),
    sep = "/"
  ),
  "TRUE/FALSE",
  grepl(
    "../../../notebooks/hypotheses/H08.html",
    preparation_test_text,
    fixed = TRUE
  ) &&
    !grepl(
      "../../../notebooks/hypotheses/H08.html",
      qmd_text,
      fixed = TRUE
    )
)

helper_text <- paste(
  readLines(helper_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
helper_compact <- gsub("[[:space:]]+", " ", helper_text)
helper_contracts <- c(
  "file.copy(source_path, rendered_source_path, overwrite = TRUE)",
  "setdiff(manifest_files, output_path)",
  "write_csv_artifact(inventory, output_path, producer)"
)
helper_pass <- vapply(
  helper_contracts,
  grepl,
  logical(1),
  x = helper_compact,
  fixed = TRUE
)
add_check(
  "helper confinement and non-circularity",
  paste0(sum(helper_pass), "/", length(helper_pass)),
  paste0(length(helper_pass), "/", length(helper_pass)),
  all(helper_pass)
)

list_artifacts <- function(path, pattern = NULL) {
  if (!dir.exists(path)) {
    return(character())
  }
  list.files(
    path,
    pattern = pattern,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = FALSE
  )
}

rendered_dir <- file.path(root, "_build/nathealth/audit/hypotheses/H08")
decision_files <- file.path(
  root,
  c(
    "audit/decisions/answer_in_brief_callout.md",
    "audit/decisions/bootstrap_execution_policy.md",
    "audit/decisions/figure_readability_and_layout.md",
    "audit/decisions/gap_timing_unaware_dataset_terminology.md",
    "audit/decisions/hypothesis_preparation_provenance_companions.md",
    "audit/decisions/model_reporting.md",
    "audit/decisions/p_value_display_conventions.md",
    "audit/decisions/paired_placement_comparison_display.md",
    "audit/decisions/site_display_conventions.md",
    "audit/decisions/l10_numerical_zero_normalization.md"
  )
)
metric011_files <- file.path(
  root,
  c(
    "audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv",
    "audit/reconciliation/l10_METRIC-011/primary_scientific_cell_changes.csv"
  )
)
predicted_files <- unique(c(
  file.path(root, "_quarto-nathealth.yml"),
  qmd_path,
  html_path,
  build_qmd_path,
  file.path(root, "notebooks/hypotheses/H08.qmd"),
  file.path(root, "_build/nathealth/notebooks/hypotheses/H08.html"),
  file.path(root, "config/site_display_registry.csv"),
  file.path(root, "config/metric_display_registry.csv"),
  file.path(root, "renv.lock"),
  file.path(root, "audit/hypotheses/H03-H11_gated_workflow.qmd"),
  decision_files,
  metric011_files,
  file.path(root, "scripts/pipeline/paths_io.R"),
  file.path(root, "scripts/pipeline/multiplicity.R"),
  file.path(root, "scripts/pipeline/p_value_display.R"),
  file.path(
    root,
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
  ),
  list_artifacts(file.path(
    rendered_dir,
    "H08_analysis_preparation_files"
  )),
  list_artifacts(file.path(root, "audit/hypotheses/H08")),
  list_artifacts(file.path(root, "scripts/hypotheses/H08"), "\\.R$"),
  list_artifacts(file.path(root, "tests/hypotheses/H08"), "\\.R$"),
  list_artifacts(file.path(root, "artifacts/06_model_data/H08")),
  list_artifacts(file.path(root, "artifacts/07_models/H08")),
  list_artifacts(file.path(root, "artifacts/08_diagnostics/H08")),
  list_artifacts(file.path(root, "artifacts/09_tables/H08")),
  list_artifacts(file.path(root, "artifacts/10_figures/H08")),
  list_artifacts(file.path(root, "artifacts/11_source_data/H08")),
  setdiff(
    list_artifacts(file.path(root, "artifacts/12_manifests/H08")),
    manifest_path
  )
))
predicted_files <- predicted_files[
  !grepl(
    "audit/handoffs/H08_(?:worker_handoff|shared_change_request)\\.md$",
    predicted_files,
    perl = TRUE
  )
]
predicted_exists <- file.exists(predicted_files) & !dir.exists(predicted_files)
predicted_relative <- substring(
  normalizePath(
    predicted_files[predicted_exists],
    winslash = "/",
    mustWork = TRUE
  ),
  nchar(root) + 2L
)
add_check(
  "prospective helper inventory",
  paste(
    length(predicted_relative),
    !anyDuplicated(predicted_relative),
    sep = "/"
  ),
  "complete/unique",
  all(predicted_exists) &&
    !anyDuplicated(predicted_relative) &&
    !manifest_rel %in% predicted_relative
)

source_data_contract <- c(
  "artifacts/11_source_data/H08/H08_preparation_sample_support.csv" = 18L,
  "artifacts/11_source_data/H08/H08_preparation_vlsq_score_distribution.csv" = 24L,
  "artifacts/11_source_data/H08/H08_preparation_vlsq_site_support.csv" = 9L,
  "artifacts/11_source_data/H08/H08_preparation_site_support.csv" = 153L,
  "artifacts/11_source_data/H08/H08_preparation_site_support_summary.csv" = 17L,
  "artifacts/11_source_data/H08/H08_preparation_metric_availability.csv" = 56L
)
source_rows <- vapply(
  names(source_data_contract),
  function(path) nrow(read.csv(file.path(root, path), check.names = FALSE)),
  integer(1)
)
add_check(
  "frozen source-data rows",
  paste(source_rows, collapse = "/"),
  paste(source_data_contract, collapse = "/"),
  identical(unname(source_rows), unname(source_data_contract))
)

family_audit <- read.csv(
  file.path(root, "artifacts/09_tables/H08/H08_family_audit.csv"),
  check.names = FALSE
)
add_check(
  "FDR family preservation",
  paste(
    nrow(family_audit),
    sum(family_audit$planned_n),
    sum(family_audit$adjusted_significant_n),
    sep = "/"
  ),
  "8/72/0",
  nrow(family_audit) == 8L &&
    all(family_audit$planned_n == 9L) &&
    all(family_audit$observed_raw_p == 9L) &&
    all(family_audit$complete_nine_member_family) &&
    all(family_audit$independent_recalculation_matches) &&
    sum(family_audit$adjusted_significant_n) == 0L
)

qa <- read.csv(
  file.path(root, "artifacts/12_manifests/H08/H08_figure_physical_size_qa.csv"),
  check.names = FALSE
)
companion_qa <- qa[qa$figure_id %in% expected_figures, , drop = FALSE]
qa_paths <- file.path(root, companion_qa$path)
qa_exact <- vapply(qa_paths, sha256_file, character(1)) ==
  companion_qa$figure_sha256
add_check(
  "companion figure physical-size baseline",
  paste(
    nrow(companion_qa),
    min(companion_qa$effective_final_essential_text_pt),
    sum(qa_exact),
    sep = "/"
  ),
  "3/>=7/3",
  nrow(companion_qa) == 3L &&
    all(companion_qa$effective_final_essential_text_pt >= 7) &&
    all(companion_qa$status == "PASS") &&
    all(qa_exact)
)

required_phrases <- c(
  "gap-timing-unaware dataset",
  "at least 50% valid minutes per hour",
  "at least 80% valid hours per day",
  "timing of the remaining missing observations",
  "time-sensitive primary metric dataset",
  "Exact evaluated Wilkinson formulae",
  "complete nine-test",
  "no FDR-adjusted p-value met the 0.050 criterion",
  "bounded maintenance rebuilt only the six primary-dataset L10 model branches"
)
phrase_pass <- vapply(
  required_phrases,
  grepl,
  logical(1),
  x = qmd_compact,
  fixed = TRUE
)
add_check(
  "scientific preservation phrases",
  paste0(sum(phrase_pass), "/", length(phrase_pass)),
  paste0(length(phrase_pass), "/", length(phrase_pass)),
  all(phrase_pass)
)

phase4 <- read.csv(
  file.path(root, "audit/report_harmonization/phase4_corpus_manifest.csv"),
  check.names = FALSE
)
h08_phase4 <- phase4[
  phase4$source %in%
    c(
      "notebooks/hypotheses/H08.qmd",
      "audit/hypotheses/H08/H08_analysis_preparation.qmd"
    ),
  ,
  drop = FALSE
]
add_check(
  "phase4 H08 historical classification",
  paste(
    nrow(h08_phase4),
    sum(
      h08_phase4$source_sha256 %in%
        c(
          "1b6b50b21e22d60909a65b125ce74be54829e5efc10de33f888fcd294c7374b1",
          "3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d"
        )
    ),
    sep = "/"
  ),
  "2/2",
  nrow(h08_phase4) == 2L &&
    setequal(
      h08_phase4$html_sha256,
      c(
        "a08a888a40ec58669c61a47b7500159388577eaad49ece5440b9bee9da6a93e1",
        "95f5ba0aede0ee6cf0d1b65fcdc53623d52810f8316c846cb214b4fb34a5f135"
      )
    )
)

build_root <- file.path(root, "_build/nathealth")
build_entries <- list.files(
  build_root,
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
build_symlinks <- build_entries[nzchar(Sys.readlink(build_entries))]
build_files <- build_entries[
  file.exists(build_entries) & !dir.exists(build_entries)
]
add_check("build files", length(build_files), 851L, length(build_files) == 851L)
add_check(
  "build symlinks",
  length(build_symlinks),
  0L,
  length(build_symlinks) == 0L
)

quarto_version <- trimws(system2("quarto", "--version", stdout = TRUE))
add_check(
  "Quarto version",
  paste(quarto_version, collapse = " "),
  "1.9.37",
  identical(quarto_version[[1L]], "1.9.37")
)

checks$r_version <- as.character(getRversion())
checks$digest_version <- as.character(utils::packageVersion("digest"))
checks$prospective_manifest_rows <- length(predicted_relative)
dir.create(dirname(verification_path), recursive = TRUE, showWarnings = FALSE)
write.csv(checks, verification_path, row.names = FALSE, na = "")

failures <- checks$status != "PASS"
if (any(failures)) {
  print(checks[failures, , drop = FALSE])
  stop("H08 companion REPORT-018 release verification failed", call. = FALSE)
}

cat(sprintf(
  paste0(
    "H08_COMPANION_REPORT018_RELEASE=PASS checks=%d/%d pins=%d/%d ",
    "result_acceptance=31/31 chunks=%d tables=%d figures=%d mermaid=%d ",
    "links=%d manifest=%d/%d+%d prospective_manifest=%d ",
    "forbidden_calls=%d build=%d symlinks=%d R=%s digest=%s quarto=%s\n"
  ),
  nrow(checks),
  nrow(checks),
  sum(pin_exact),
  nrow(pins),
  length(chunks),
  length(table_labels),
  length(figure_labels),
  mermaid_count,
  length(relative_targets),
  sum(manifest_exact),
  nrow(manifest),
  length(manifest_mismatch_paths),
  length(predicted_relative),
  length(forbidden_observed),
  length(build_files),
  length(build_symlinks),
  as.character(getRversion()),
  as.character(utils::packageVersion("digest")),
  quarto_version[[1L]]
))
