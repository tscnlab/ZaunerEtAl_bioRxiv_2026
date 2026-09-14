#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
pins_path <- file.path(
  root,
  "audit/report_harmonization/report018_h09_companion_release_pins.csv"
)
verification_path <- file.path(
  root,
  "audit/report_harmonization/report018_h09_companion_release_verification.csv"
)
qmd_rel <- "audit/hypotheses/H09/H09_analysis_preparation.qmd"
qmd_path <- file.path(root, qmd_rel)
build_qmd_rel <- paste0(
  "_build/nathealth/audit/hypotheses/H09/",
  "H09_analysis_preparation.qmd"
)
build_qmd_path <- file.path(root, build_qmd_rel)
html_rel <- paste0(
  "_build/nathealth/audit/hypotheses/H09/",
  "H09_analysis_preparation.html"
)
html_path <- file.path(root, html_rel)
source_html_rel <- "audit/hypotheses/H09/H09_analysis_preparation.html"
source_html_path <- file.path(root, source_html_rel)
manifest_rel <- "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv"
manifest_path <- file.path(root, manifest_rel)
helper_rel <- "scripts/hypotheses/H09/build_h09_preparation_report_manifest.R"
helper_path <- file.path(root, helper_rel)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H09 companion release verification requires R 4.6.1", call. = FALSE)
}

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
  !any(pins$relative_path == sub(paste0("^", root, "/"), "", pins_path))
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
    paste0(
      "audit/report_harmonization/",
      "report018_h09_order56b_result_independent_acceptance_manifest.csv"
    )
  ),
  check.names = FALSE
)
result_acceptance_files <- ifelse(
  startsWith(result_acceptance_manifest$path, "/"),
  result_acceptance_manifest$path,
  file.path(root, result_acceptance_manifest$path)
)
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
  "37/37",
  nrow(result_acceptance_manifest) == 37L &&
    !anyDuplicated(result_acceptance_manifest$path) &&
    !any(
      result_acceptance_manifest$path ==
        paste0(
          "audit/report_harmonization/",
          "report018_h09_order56b_result_independent_acceptance_manifest.csv"
        )
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
add_check("R chunks", length(chunks), 22L, length(chunks) == 22L)
add_check(
  "R chunk parse",
  sum(chunk_parse),
  length(chunk_parse),
  all(chunk_parse)
)

expected_tables <- c(
  "tbl-h09-prep-input-identities",
  "tbl-h09-prep-integrity-checks",
  "tbl-h09-prep-score-audit",
  "tbl-h09-prep-predictor-contract",
  "tbl-h09-prep-metric-contract",
  "tbl-h09-prep-primary-samples",
  "tbl-h09-prep-common-samples",
  "tbl-h09-prep-primary-formulas",
  "tbl-h09-prep-sensitivity-formulas",
  "tbl-h09-prep-families",
  "tbl-h09-prep-diagnostic-summary",
  "tbl-h09-prep-sensitivity-map",
  "tbl-h09-prep-boundary",
  "tbl-h09-prep-intermediate-artifacts",
  "tbl-h09-prep-code-map",
  "tbl-h09-prep-script-map",
  "tbl-h09-prep-reader-manifest-check",
  "tbl-h09-prep-key-output-identities",
  "tbl-h09-prep-execution"
)
expected_figures <- "fig-h09-prep-sample-support"
table_labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: tbl-h09-", qmd_lines, value = TRUE)
)
figure_labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: fig-h09-", qmd_lines, value = TRUE)
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
  "nlme::lme",
  "lme",
  "stats::predict",
  "predict",
  "stats::simulate",
  "simulate",
  "boot::boot",
  "boot",
  "emmeans::emmeans",
  "emmeans",
  "h09_fit_model",
  "h09_fit_bundle",
  "h09_fit_models",
  "h09_model_diagnostics",
  "h09_residual_diagnostics",
  "h09_leave_one_site_out",
  "h09_participant_influence",
  "h09_photoperiod_sensitivity",
  "h09_participant_summary_sensitivity",
  "h09_ar1_sensitivity"
)
forbidden_observed <- intersect(calls, forbidden_calls)
add_check(
  "forbidden scientific calls",
  paste(forbidden_observed, collapse = "|"),
  "none",
  length(forbidden_observed) == 0L
)

relative_matches <- gregexpr("\\]\\((\\.\\./[^)]+)\\)", qmd_text, perl = TRUE)
relative_values <- regmatches(qmd_text, relative_matches)[[1L]]
relative_targets <- sub("^\\]\\(", "", relative_values)
relative_targets <- sub("\\)$", "", relative_targets)
relative_files <- sub("#.*$", "", relative_targets)
resolved_targets <- file.path(dirname(qmd_path), relative_files)
relative_exists <- file.exists(resolved_targets)
add_check(
  "relative reader targets resolve",
  paste0(sum(relative_exists), "/", length(relative_exists)),
  "23/23",
  length(relative_exists) == 23L &&
    length(unique(relative_targets)) == 22L &&
    all(relative_exists)
)
dynamic_result_links <- grep(
  "^../../../notebooks/hypotheses/H09\\.qmd",
  relative_targets,
  value = TRUE
)
expected_dynamic_links <- c(
  "../../../notebooks/hypotheses/H09.qmd",
  "../../../notebooks/hypotheses/H09.qmd#h09-preregistration-deviations"
)
add_check(
  "dynamic result links",
  paste(sort(dynamic_result_links), collapse = "|"),
  paste(sort(expected_dynamic_links), collapse = "|"),
  identical(sort(dynamic_result_links), sort(expected_dynamic_links))
)

profile_lines <- readLines(
  file.path(root, "_quarto-nathealth.yml"),
  warn = FALSE,
  encoding = "UTF-8"
)
profile_trim <- trimws(profile_lines)
result_profile_index <- which(profile_trim == "- notebooks/hypotheses/H09.qmd")
companion_profile_index <- which(
  profile_trim == "- audit/hypotheses/H09/H09_analysis_preparation.qmd"
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
    593181,
    "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
    sep = "/"
  ),
  file_bytes(html_path) == 593181 &&
    sha256_file(html_path) ==
      "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05"
)
add_check(
  "historical source-side HTML",
  paste(file_bytes(source_html_path), sha256_file(source_html_path), sep = "/"),
  paste(
    593181,
    "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
    sep = "/"
  ),
  file_bytes(source_html_path) == 593181 &&
    sha256_file(source_html_path) ==
      "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05"
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
  "scripts/hypotheses/H09/h09_contract.R",
  "scripts/hypotheses/H09/run_h09_stage2.R",
  "audit/decisions/figure_readability_and_layout.md",
  "_quarto-nathealth.yml",
  "audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "artifacts/10_figures/H09/H09_diagnostics_chest.pdf",
  "artifacts/10_figures/H09/H09_diagnostics_chest.png",
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.pdf",
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.png",
  "artifacts/10_figures/H09/H09_paired_placement_effects.pdf",
  "artifacts/10_figures/H09/H09_paired_placement_effects.png",
  "artifacts/10_figures/H09/H09_primary_effects.pdf",
  "artifacts/10_figures/H09/H09_primary_effects.png",
  "artifacts/12_manifests/H09/H09_figure_manifest.csv",
  "_build/nathealth/notebooks/hypotheses/H09.html",
  "notebooks/hypotheses/H09.qmd",
  "config/metric_display_registry.csv",
  "artifacts/06_model_data/H09/H09_base_bundle_audit.csv",
  "artifacts/06_model_data/H09/H09_input_audit.csv"
)
add_check(
  "current preparation manifest rows",
  nrow(manifest),
  132L,
  nrow(manifest) == 132L
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
  113L,
  sum(manifest_exact) == 113L
)
add_check(
  "current preparation manifest expected mismatches",
  paste(sort(manifest_mismatch_paths), collapse = "|"),
  paste(sort(expected_mismatch_paths), collapse = "|"),
  setequal(manifest_mismatch_paths, expected_mismatch_paths)
)

preparation_test_text <- paste(
  readLines(
    file.path(root, "tests/hypotheses/H09/test_h09_preparation_report.R"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
result_qmd_text <- paste(
  readLines(
    file.path(root, "notebooks/hypotheses/H09.qmd"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
stale_test_contracts <- c(
  companion_html_literal = grepl(
    "../../../notebooks/hypotheses/H09.html",
    preparation_test_text,
    fixed = TRUE
  ) &&
    !grepl("../../../notebooks/hypotheses/H09.html", qmd_text, fixed = TRUE),
  result_html_literal = grepl(
    "../../audit/hypotheses/H09/H09_analysis_preparation.html",
    preparation_test_text,
    fixed = TRUE
  ) &&
    !grepl(
      "../../audit/hypotheses/H09/H09_analysis_preparation.html",
      result_qmd_text,
      fixed = TRUE
    ),
  profile_absence = grepl(
    "stopifnot(!grepl(prep_profile_path, profile, fixed = TRUE))",
    preparation_test_text,
    fixed = TRUE
  ) &&
    length(companion_profile_index) == 1L
)
add_check(
  "historical companion test classifications",
  paste0(sum(stale_test_contracts), "/", length(stale_test_contracts)),
  "3/3",
  all(stale_test_contracts)
)

helper_text <- paste(
  readLines(helper_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
helper_compact <- gsub("[[:space:]]+", " ", helper_text)
helper_contracts <- c(
  "if (!file.copy(paths$qmd, paths$rendered_qmd, overwrite = TRUE))",
  "files <- setdiff(files, output_path)",
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

h09_roots <- file.path(
  root,
  c(
    "scripts/hypotheses/H09",
    "tests/hypotheses/H09",
    "audit/hypotheses/H09",
    "artifacts/06_model_data/H09",
    "artifacts/07_models/H09",
    "artifacts/08_diagnostics/H09",
    "artifacts/09_tables/H09",
    "artifacts/10_figures/H09",
    "artifacts/11_source_data/H09",
    "artifacts/12_manifests/H09"
  )
)
h09_files <- unlist(lapply(h09_roots, list_artifacts), use.names = FALSE)
preparation_assets <- list_artifacts(file.path(
  root,
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation_files"
))
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
    "audit/decisions/placement_decision.md",
    "audit/decisions/reader_facing_symlog_scale.md",
    "audit/decisions/site_display_conventions.md"
  )
)
supporting_files <- file.path(
  root,
  c(
    "AGENTS.md",
    "renv.lock",
    "_quarto.yml",
    "_quarto-nathealth.yml",
    "notebooks/hypotheses/H09.qmd",
    "_build/nathealth/notebooks/hypotheses/H09.html",
    "config/metric_display_registry.csv",
    "config/site_display_registry.csv",
    "audit/evidence/preregistration_contract.md",
    "audit/hypotheses/H03-H11_gated_workflow.qmd",
    "audit/hypotheses/H09-H11_migration_map.md",
    "scripts/pipeline/paths_io.R",
    "scripts/pipeline/p_value_display.R",
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
  )
)
predicted_files <- unique(c(
  qmd_path,
  html_path,
  build_qmd_path,
  file.path(root, "notebooks/hypotheses/H09.qmd"),
  file.path(root, "_build/nathealth/notebooks/hypotheses/H09.html"),
  file.path(root, "_quarto-nathealth.yml"),
  h09_files,
  preparation_assets,
  decision_files,
  supporting_files
))
predicted_files <- predicted_files[
  !grepl(
    "audit/handoffs/H09_(?:worker_handoff|shared_change_request)\\.md$",
    predicted_files,
    perl = TRUE
  )
]
predicted_files <- setdiff(predicted_files, manifest_path)
predicted_files <- predicted_files[
  file.exists(predicted_files) & !dir.exists(predicted_files)
]
predicted_relative <- substring(
  sort(unique(normalizePath(
    predicted_files,
    winslash = "/",
    mustWork = TRUE
  ))),
  nchar(root) + 2L
)
add_check(
  "prospective helper inventory before render",
  paste(length(predicted_relative), length(preparation_assets), sep = "/"),
  "449/0",
  length(predicted_relative) == 449L &&
    length(preparation_assets) == 0L &&
    !anyDuplicated(predicted_relative) &&
    !manifest_rel %in% predicted_relative
)

model_frame_index <- read.csv(
  file.path(root, "artifacts/06_model_data/H09/H09_model_frame_index.csv"),
  check.names = FALSE
)
add_check(
  "companion figure frozen source",
  paste(
    nrow(model_frame_index),
    length(unique(model_frame_index$frame_id)),
    sep = "/"
  ),
  "108/108",
  nrow(model_frame_index) == 108L && !anyDuplicated(model_frame_index$frame_id)
)

required_phrases <- c(
  "gap-timing-unaware dataset",
  "50%-per-hour",
  "80%-per-day",
  "remaining gaps' time of day",
  "time-sensitive primary dataset",
  "mctq_hour_centered",
  "meq_10_centered",
  "one hour later corrected midsleep",
  "10 score points toward greater morning preference"
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
h09_phase4 <- phase4[
  phase4$source %in%
    c(
      "notebooks/hypotheses/H09.qmd",
      "audit/hypotheses/H09/H09_analysis_preparation.qmd"
    ),
  ,
  drop = FALSE
]
add_check(
  "phase4 H09 historical classification",
  paste(
    nrow(h09_phase4),
    sum(
      h09_phase4$source_sha256 %in%
        c(
          "c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6",
          "7563a933289b1c4a2275eead58ae8cfaa6492fb0a27b7202f4a9be516eb88a46"
        )
    ),
    sep = "/"
  ),
  "2/2",
  nrow(h09_phase4) == 2L &&
    setequal(
      h09_phase4$html_sha256,
      c(
        "ce6c4c644af675e5feb25dcbc834b55c3ddfc87ec3dc581c95366edc0de067b1",
        "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05"
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
checks$prospective_manifest_rows_before_render <- length(predicted_relative)
checks$expected_manifest_rows_after_render <- 450L
dir.create(dirname(verification_path), recursive = TRUE, showWarnings = FALSE)
write.csv(checks, verification_path, row.names = FALSE, na = "")

failures <- checks$status != "PASS"
if (any(failures)) {
  print(checks[failures, , drop = FALSE])
  stop("H09 companion REPORT-018 release verification failed", call. = FALSE)
}

cat(sprintf(
  paste0(
    "H09_COMPANION_REPORT018_RELEASE=PASS checks=%d/%d pins=%d/%d ",
    "result_acceptance=37/37 chunks=%d tables=%d figures=%d mermaid=%d ",
    "links=%d/%d manifest=%d/%d+%d prospective_manifest=%d->450 ",
    "stale_test=3/3 forbidden_calls=%d build=%d symlinks=%d ",
    "R=%s digest=%s quarto=%s\n"
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
  length(unique(relative_targets)),
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
