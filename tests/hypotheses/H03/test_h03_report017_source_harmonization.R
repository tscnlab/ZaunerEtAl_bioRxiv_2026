# Source-only REPORT-017 checks for the synchronized H03 result and companion.
# This test parses but never executes either QMD.

suppressPackageStartupMessages({
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H03 REPORT-017 source checks require R 4.6.1", call. = FALSE)
}
source(file.path(root, "scripts/pipeline/paths_io.R"))

result_path <- file.path(root, "notebooks/hypotheses/H03.qmd")
companion_path <- file.path(
  root,
  "audit/hypotheses/H03/H03_analysis_preparation.qmd"
)
stopifnot(file.exists(result_path), file.exists(companion_path))

read_source <- function(path) {
  readLines(path, warn = FALSE, encoding = "UTF-8")
}

collapse_source <- function(lines) paste(lines, collapse = "\n")

count_fixed <- function(text, pattern) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) 0L else length(matches)
}

extract_r_chunks <- function(lines) {
  starts <- grep("^```\\{r(?:[ ,}]|$)", lines, perl = TRUE)
  chunks <- vector("list", length(starts))
  names(chunks) <- rep(NA_character_, length(starts))
  for (index in seq_along(starts)) {
    start <- starts[[index]]
    relative_end <- grep(
      "^```[[:space:]]*$",
      lines[seq.int(start + 1L, length(lines))]
    )[[1L]]
    end <- start + relative_end
    code <- lines[seq.int(start + 1L, end - 1L)]
    label_line <- grep("^#\\| label: ", code, value = TRUE)
    if (length(label_line) == 1L) {
      names(chunks)[[index]] <- sub("^#\\| label: ", "", label_line)
    }
    chunks[[index]] <- code
  }
  chunks
}

extract_labels <- function(lines, prefix = NULL) {
  labels <- sub(
    "^#\\| label: ",
    "",
    grep("^#\\| label: ", lines, value = TRUE)
  )
  if (is.null(prefix)) labels else labels[startsWith(labels, prefix)]
}

extract_inline_r <- function(text) {
  matches <- regmatches(
    text,
    gregexpr("`r[[:space:]]+[^`]+`", text, perl = TRUE)
  )[[1L]]
  if (length(matches) == 1L && identical(matches, character(0))) {
    character()
  } else {
    sort(unique(matches))
  }
}

extract_top_assignments <- function(chunks) {
  assignments <- unlist(lapply(chunks, function(chunk) {
    expressions <- parse(text = paste(chunk, collapse = "\n"))
    vapply(expressions, function(expression) {
      if (
        is.call(expression) &&
          identical(as.character(expression[[1L]]), "<-") &&
          is.symbol(expression[[2L]])
      ) {
        as.character(expression[[2L]])
      } else {
        NA_character_
      }
    }, character(1L))
  }), use.names = FALSE)
  sort(unique(stats::na.omit(assignments)))
}

extract_pattern_set <- function(text, pattern) {
  matches <- regmatches(text, gregexpr(pattern, text, perl = TRUE))[[1L]]
  if (length(matches) == 1L && identical(matches, character(0))) {
    character()
  } else {
    sort(unique(matches))
  }
}

set_sha256 <- function(values) {
  canonical <- paste(sort(unique(values)), collapse = "\n")
  unname(as.character(openssl::sha256(charToRaw(canonical))))
}

extract_links <- function(text) {
  matches <- regmatches(
    text,
    gregexpr("\\]\\([^)]+\\)", text, perl = TRUE)
  )[[1L]]
  if (length(matches) == 1L && identical(matches, character(0))) {
    return(character())
  }
  sub("^\\]\\(([^)]+)\\)$", "\\1", matches)
}

strip_fenced_blocks <- function(lines) {
  inside <- FALSE
  keep <- logical(length(lines))
  for (index in seq_along(lines)) {
    if (grepl("^```", lines[[index]])) {
      inside <- !inside
      next
    }
    keep[[index]] <- !inside
  }
  lines[keep]
}

resolve_links <- function(source_path, targets) {
  internal <- targets[!grepl("^[a-z]+://", targets, ignore.case = TRUE)]
  for (target in internal) {
    clean <- sub("^<|>$", "", target)
    fragment <- if (grepl("#", clean, fixed = TRUE)) {
      sub("^[^#]*#", "", clean)
    } else {
      ""
    }
    file_target <- sub("#.*$", "", clean)
    if (!nzchar(file_target)) {
      resolved <- source_path
    } else {
      resolved <- normalizePath(
        file.path(dirname(source_path), file_target),
        winslash = "/",
        mustWork = TRUE
      )
    }
    stopifnot(file.exists(resolved))
    if (nzchar(fragment)) {
      linked_text <- collapse_source(read_source(resolved))
      stopifnot(grepl(paste0("{#", fragment, "}"), linked_text, fixed = TRUE))
    }
  }
  invisible(TRUE)
}

result_lines <- read_source(result_path)
companion_lines <- read_source(companion_path)
result_text <- collapse_source(result_lines)
companion_text <- collapse_source(companion_lines)
result_chunks <- extract_r_chunks(result_lines)
companion_chunks <- extract_r_chunks(companion_lines)

invisible(lapply(result_chunks, function(chunk) {
  parse(text = paste(chunk, collapse = "\n"))
}))
invisible(lapply(companion_chunks, function(chunk) {
  parse(text = paste(chunk, collapse = "\n"))
}))

expected_result_tables <- c(
  "tbl-h03-primary-results",
  "tbl-h03-omnibus",
  "tbl-h03-near-site-factorization",
  "tbl-h03-fixed-r2",
  "tbl-h03-participant-random-intercept",
  "tbl-h03-primary-diagnostics",
  "tbl-h03-sensitivities",
  "tbl-h03-temporal-fit",
  "tbl-h03-temporal-allocation",
  "tbl-h03-temporal-diagnostics",
  "tbl-h03-latitude-slopes",
  "tbl-h03-overall-samples",
  "tbl-h03-category-support",
  "tbl-h03-formulas"
)
expected_result_figures <- c(
  "fig-h03-primary-estimates",
  "fig-h03-near-site-context",
  "fig-h03-primary-diagnostics",
  "fig-h03-paired-placement",
  "fig-h03-temporal-near-eye",
  "fig-h03-temporal-chest",
  "fig-h03-temporal-diagnostics",
  "fig-h03-latitude-slopes"
)
expected_companion_tables <- c(
  "tbl-h03-prep-input-identities",
  "tbl-h03-prep-integrity",
  "tbl-h03-prep-zero-support",
  "tbl-h03-prep-primary-samples",
  "tbl-h03-prep-participant-day-support",
  "tbl-h03-prep-category-support",
  "tbl-h03-prep-site-cell-support",
  "tbl-h03-prep-primary-specification",
  "tbl-h03-prep-primary-tests",
  "tbl-h03-prep-estimand-contract",
  "tbl-h03-prep-interaction-gate",
  "tbl-h03-prep-multiplicity",
  "tbl-h03-prep-glm-r-squared",
  "tbl-h03-prep-participant-random-intercept",
  "tbl-h03-prep-primary-diagnostics",
  "tbl-h03-prep-zero-diagnostics",
  "tbl-h03-prep-residual-acf",
  "tbl-h03-prep-influence",
  "tbl-h03-prep-sensitivity-samples",
  "tbl-h03-prep-sensitivity-tests",
  "tbl-h03-prep-temporal-models",
  "tbl-h03-prep-temporal-performance",
  "tbl-h03-prep-latitude",
  "tbl-h03-prep-script-map",
  "tbl-h03-prep-output-map",
  "tbl-h03-prep-boundary",
  "tbl-h03-prep-environment"
)
expected_companion_figures <- c(
  "fig-h03-prep-positive-distribution",
  "fig-h03-prep-category-support",
  "fig-h03-prep-site-category-support",
  "fig-h03-prep-clock-category-support"
)

result_tables <- extract_labels(result_lines, "tbl-h03-")
result_figures <- extract_labels(result_lines, "fig-h03-")
companion_tables <- extract_labels(companion_lines, "tbl-h03-prep-")
companion_figures <- extract_labels(companion_lines, "fig-h03-prep-")
stopifnot(
  identical(result_tables, expected_result_tables),
  identical(result_figures, expected_result_figures),
  identical(companion_tables, expected_companion_tables),
  identical(companion_figures, expected_companion_figures),
  length(unique(result_tables)) == 14L,
  length(unique(result_figures)) == 8L,
  length(unique(companion_tables)) == 27L,
  length(unique(companion_figures)) == 4L,
  result_tables[[1L]] == "tbl-h03-primary-results",
  result_figures[[1L]] == "fig-h03-primary-estimates"
)

result_links <- extract_links(result_text)
companion_links <- extract_links(companion_text)
resolve_links(result_path, result_links)
resolve_links(companion_path, companion_links)

auxiliary_target <- paste0(
  "../../audit/hypotheses/H03/H03_analysis_preparation.qmd",
  "#sec-h03-prep-participant-random-intercept"
)
stopifnot(
  count_fixed(result_text, auxiliary_target) == 1L,
  count_fixed(
    companion_text,
    "{#sec-h03-prep-participant-random-intercept}"
  ) == 1L,
  count_fixed(
    companion_text,
    "../../../notebooks/hypotheses/H03.qmd"
  ) >= 2L,
  count_fixed(result_text, "{#h03-preregistration-deviations}") == 1L
)
for (id in c("013", "014", "022", "023", "024")) {
  target <- paste0(
    "../preregistration_deviations.qmd#dev-",
    id
  )
  stopifnot(count_fixed(result_text, target) == 1L)
}

all_links <- c(result_links, companion_links)
stopifnot(
  !any(grepl("file://|_build|/Users/|\\.html(?:#|$)", all_links)),
  !any(startsWith(all_links, "/"))
)
linked_source_data <- all_links[grepl("artifacts/11_source_data", all_links)]
expected_linked_source_data <- sort(c(
  "../../artifacts/11_source_data/H03/H03_reader_heterogeneity_category_figure_data.csv",
  "../../artifacts/11_source_data/H03/H03_reader_latitude_site_support.csv",
  "../../artifacts/11_source_data/H03/H03_reader_temporal_chest_curves.csv",
  "../../artifacts/11_source_data/H03/H03_reader_temporal_chest_ratios.csv",
  "../../artifacts/11_source_data/H03/H03_reader_temporal_chest_support.csv",
  "../../artifacts/11_source_data/H03/H03_reader_temporal_near_eye_curves.csv",
  "../../artifacts/11_source_data/H03/H03_reader_temporal_near_eye_ratios.csv",
  "../../artifacts/11_source_data/H03/H03_reader_temporal_near_eye_support.csv",
  "../../artifacts/11_source_data/H03/H03_reader_temporal_residual_bins.csv",
  "../../artifacts/11_source_data/H03/H03_reader_temporal_residual_points.csv",
  "../../artifacts/11_source_data/H03/H03_reader_temporal_zero_calibration.csv",
  "../../../artifacts/11_source_data/H03/H03_preparation_category_support.csv",
  "../../../artifacts/11_source_data/H03/H03_preparation_clock_category_support.csv",
  "../../../artifacts/11_source_data/H03/H03_preparation_participant_day_support.csv",
  "../../../artifacts/11_source_data/H03/H03_preparation_positive_response_distribution.csv",
  "../../../artifacts/11_source_data/H03/H03_preparation_site_category_support.csv"
))
stopifnot(
  length(linked_source_data) == 16L,
  length(unique(linked_source_data)) == 16L,
  identical(sort(linked_source_data), expected_linked_source_data)
)

result_reader_text <- collapse_source(strip_fenced_blocks(result_lines))
companion_reader_text <- collapse_source(strip_fenced_blocks(companion_lines))
reader_text <- paste(result_reader_text, companion_reader_text, sep = "\n")
stopifnot(
  grepl("category-by-site interaction", reader_text, fixed = TRUE),
  grepl(
    "Participant-level variation",
    paste(result_text, companion_text),
    fixed = TRUE
  ),
  grepl("shared country-coded site", reader_text, ignore.case = TRUE),
  !grepl("light-source-category-by-site", reader_text, fixed = TRUE),
  !grepl("Participant heterogeneity", reader_text, fixed = TRUE),
  !grepl("submitted site palette", reader_text, ignore.case = TRUE),
  !grepl("submitted-manuscript site", reader_text, ignore.case = TRUE),
  !grepl("Submitted site registry", reader_text, fixed = TRUE),
  !grepl("Submitted site-display registry", reader_text, fixed = TRUE),
  !grepl("\\bH03-F[1-4]", reader_text, perl = TRUE),
  !grepl("\\bBH\\b", reader_text, perl = TRUE),
  !grepl("—", reader_text, fixed = TRUE),
  count_fixed(result_text, "lightbox: true") == 1L,
  count_fixed(companion_text, "lightbox: true") == 1L,
  grepl("## About this analysis record", companion_text, fixed = TRUE),
  grepl("Shared country-coded site registry", companion_text, fixed = TRUE),
  grepl("PASS = \"Verified\"", companion_text, fixed = TRUE),
  grepl("FAIL = \"Review needed\"", companion_text, fixed = TRUE)
)

disclosures <- c(
  "Show detailed primary model checks",
  "Show detailed sensitivity results",
  "Show exploratory nonlinear time-of-day details",
  "Show exploratory latitude details"
)
stopifnot(all(vapply(
  disclosures,
  function(value) count_fixed(result_text, value) == 1L,
  logical(1L)
)))

required_formulas <- c(
  "geo_medi_1h ~ site + light_source",
  "geo_medi_1h ~ site * light_source",
  "geo_medi_1h ~ 0 + site_source_cell",
  paste0(
    "geo_medi_1h ~ 0 + light_source + ",
    "light_source:absolute_latitude_10deg_centered"
  ),
  "geo_medi_1h ~ site * light_source + (1 | participant)"
)
stopifnot(all(vapply(
  required_formulas,
  function(value) grepl(value, paste(result_text, companion_text), fixed = TRUE),
  logical(1L)
)))

auxiliary_summary_path <- file.path(
  root,
  "artifacts/09_tables/H03/",
  "H03_near_eye_participant_random_intercept_summary.csv"
)
auxiliary_shapley_path <- file.path(
  root,
  "artifacts/09_tables/H03/",
  "H03_near_eye_participant_random_intercept_marginal_r2_shapley.csv"
)
auxiliary_checks_path <- file.path(
  root,
  "artifacts/08_diagnostics/H03/",
  "H03_near_eye_participant_random_intercept_shapley_models.csv"
)
auxiliary_diagnostics_path <- file.path(
  root,
  "artifacts/08_diagnostics/H03/",
  "H03_near_eye_participant_random_intercept_diagnostics.csv"
)
auxiliary_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H03/",
  "H03_near_eye_participant_random_intercept_manifest.csv"
)
auxiliary_summary <- readr::read_csv(
  auxiliary_summary_path,
  show_col_types = FALSE
)
auxiliary_shapley <- readr::read_csv(
  auxiliary_shapley_path,
  show_col_types = FALSE
)
auxiliary_checks <- readr::read_csv(
  auxiliary_checks_path,
  show_col_types = FALSE
)
auxiliary_diagnostics <- readr::read_csv(
  auxiliary_diagnostics_path,
  show_col_types = FALSE
)
auxiliary_manifest <- readr::read_csv(
  auxiliary_manifest_path,
  show_col_types = FALSE
)
stopifnot(
  nrow(auxiliary_summary) == 1L,
  auxiliary_summary$formula[[1L]] == required_formulas[[5L]],
  auxiliary_summary$family[[1L]] == "glmmTMB Tweedie",
  auxiliary_summary$link[[1L]] == "log",
  auxiliary_summary$fitting_method[[1L]] == "maximum likelihood",
  auxiliary_summary$observations[[1L]] == 17935L,
  auxiliary_summary$participants[[1L]] == 140L,
  auxiliary_summary$participant_days[[1L]] == 801L,
  auxiliary_summary$sites[[1L]] == 9L,
  auxiliary_summary$light_source_categories[[1L]] == 7L,
  abs(auxiliary_summary$working_power_fixed[[1L]] - 1.539919) < 1e-12,
  abs(auxiliary_summary$marginal_r_squared[[1L]] - 0.7958506307640498) < 1e-12,
  abs(auxiliary_summary$conditional_r_squared[[1L]] - 0.8762255014191184) < 1e-12,
  abs(auxiliary_summary$participant_r_squared_increment[[1L]] -
    0.08037487065506854) < 1e-12,
  abs(auxiliary_summary$adjusted_participant_icc[[1L]] -
    0.39370619148067754) < 1e-12,
  abs(auxiliary_summary$unadjusted_participant_icc[[1L]] -
    0.08037487065506858) < 1e-12,
  nrow(auxiliary_shapley) == 3L,
  nrow(auxiliary_checks) == 5L,
  all(auxiliary_checks$convergence_code == 0L),
  all(auxiliary_checks$warning_count == 0L),
  all(auxiliary_checks$positive_definite_hessian),
  !any(auxiliary_checks$singular),
  abs(auxiliary_diagnostics$lag1_pearson_residual_correlation[[1L]] -
    0.28803986916258484) < 1e-12,
  abs(auxiliary_diagnostics$observed_zero_fraction[[1L]] -
    0.2775020908837469) < 1e-12,
  abs(auxiliary_diagnostics$tweedie_implied_zero_fraction[[1L]] -
    0.39774605907507543) < 1e-12
)

auxiliary_paths <- normalizePath(
  auxiliary_manifest$path,
  winslash = "/",
  mustWork = TRUE
)
stopifnot(
  nrow(auxiliary_manifest) == 6L,
  all(vapply(auxiliary_paths, artifact_sha256, character(1L)) ==
    auxiliary_manifest$sha256),
  all(file.info(auxiliary_paths)$size == auxiliary_manifest$bytes),
  all(auxiliary_manifest$r_version == "4.6.1")
)

auxiliary_required_source <- c(
  "run_h03_participant_random_intercept_assessment.R",
  "H03_near_eye_participant_random_intercept_assessment.rds",
  "H03_near_eye_participant_random_intercept_summary.csv",
  "H03_near_eye_participant_random_intercept_marginal_r2_shapley.csv",
  "H03_near_eye_participant_random_intercept_shapley_models.csv",
  "H03_near_eye_participant_random_intercept_diagnostics.csv",
  "H03_near_eye_participant_random_intercept_environment.csv",
  "H03_near_eye_participant_random_intercept_manifest.csv",
  "no random light-source slopes, participant-day effect, or AR(1) term",
  "descriptive, model-dependent, non-causal",
  "not a mixed model, random-intercept model, random-slope",
  "does not replace the accepted population-mean"
)
companion_semantic_text <- gsub("[[:space:]]+", " ", companion_text)
stopifnot(all(vapply(
  auxiliary_required_source,
  function(value) grepl(value, companion_semantic_text, fixed = TRUE),
  logical(1L)
)))

all_chunk_code <- paste(
  unlist(c(result_chunks, companion_chunks), use.names = FALSE),
  collapse = "\n"
)
forbidden_calls <- paste0(
  "(?:stats::)?glm|glmmTMB::glmmTMB|mgcv::(?:bam|gam)|",
  "bam|gam|predict|simulate|boot|bootstrap|resample|",
  "saveRDS|writeRDS|write_csv|write\\.csv|ggsave|quarto_render|",
  "dir\\.create|file\\.copy|file\\.rename|unlink"
)
stopifnot(!grepl(
  paste0("(?:", forbidden_calls, ")[[:space:]]*\\("),
  all_chunk_code,
  perl = TRUE
))

protected <- tibble::tribble(
  ~path, ~sha256, ~bytes,
  "tests/hypotheses/H03/test_h03_stage3_reader_report.R", "0af80c8dfede663d724c488f5b7947ca8635a944d789f7a552f6e932999bd3ef", 18080,
  "tests/hypotheses/H03/test_h03_preparation_report.R", "bddaa2393ead9317c5f526a00f75d2fd86e0e7efeaf84dcd2737e61b149a058a", 8412,
  "tests/hypotheses/H03/test_h03_participant_random_intercept_assessment.R", "30fa488114886eb4e9feeccc55f6f752e229585bfc1f2eb5b5a85bfba582bfc8", 7568,
  "tests/hypotheses/H03/test_h03_stage2.R", "a174e3fe2a1a7832a5f6e8e8a98a3da8d88d85bd30e22917e554ae658f7ce596", 19424,
  "artifacts/12_manifests/H03/H03_stage3_artifacts.csv", "5f4f10528f1c49d52518a6dde36d6ce0ffd71869cab9bcde382bf9c9edce3170", 83962,
  "artifacts/12_manifests/H03/H03_preparation_report_manifest.csv", "5235b02c6c542a010336eca9569b77b269deb673d4659d794393d2427146393a", 81124,
  "scripts/hypotheses/H03/run_h03_participant_random_intercept_assessment.R", "662e7ac81b3b67693023acdb196b2187d7058e863294b7b77e0105b8ca456f4c", 16328,
  "artifacts/12_manifests/H03/H03_near_eye_participant_random_intercept_manifest.csv", "81bab5291ca9f9aa24a39cae991857b8f5b39046090da2e4f4c984f4ea7c2306", 2190
)
protected_paths <- file.path(root, protected$path)
stopifnot(
  all(file.exists(protected_paths)),
  all(vapply(protected_paths, artifact_sha256, character(1L)) == protected$sha256),
  all(file.info(protected_paths)$size == protected$bytes)
)

protected_context <- c(
  "notebooks/preregistration_deviations.qmd" =
    "b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d",
  "config/site_display_registry.csv" =
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
  "_quarto-nathealth.yml" =
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  "_build/nathealth/notebooks/hypotheses/H03.html" =
    "68aa07eb7470286d0d6da76114ce7bf346ee635974fe7403c1860ad4560c3d25",
  "_build/nathealth/audit/hypotheses/H03/H03_analysis_preparation.html" =
    "813492b5b1941716c1996f8a0c1b88c658e6eefb52e2569be62744fe965308bf",
  "audit/report_harmonization/phase2_main_supplement_output_catalog.csv" =
    "43110e4f20a4e9d6257351fad4905c08587f85a28aa27d2a932b0d33b88b6894",
  "audit/decisions/h03_auxiliary_model_assessments_closure.md" =
    "85be31f6c105ea2c47a5353a32d4081dcdbc50a0738998f2106c0952c4527827",
  "audit/report_harmonization/h03_postclosure_synchronization_check.md" =
    "569767a839a34f1dc3e58ea8c5b554da23a56163a2cf48ad90d7a17cd05b1aea",
  "audit/report_harmonization/report017_h03_consolidated_full_document_audit.md" =
    "e43a703aec1d2e70a79b9bac970857fe2928b727ad46849745673770d8e0b176",
  "audit/report_harmonization/report017_h03_consolidated_change_matrix.csv" =
    "917e29f200fd9e3554e14561307c262203a5ce455eb4614e5006bf878abd313c",
  "audit/report_harmonization/report017_consolidated_document_pass_protocol.md" =
    "13b5bb6708e0b044117a48f9577026e57896a935aed58f6b512948a828fe6923",
  "audit/report_harmonization/owner_orders/34_h03_consolidated_reader_and_companion_synchronization.md" =
    "3df58a1fc775a534ec8f0770ecf3e5491a66410ec301007866085fd2c905d95a"
)
stopifnot(all(vapply(
  names(protected_context),
  function(path) artifact_sha256(file.path(root, path)) == protected_context[[path]],
  logical(1L)
)))

baked_files <- c(
  "artifacts/10_figures/H03/H03_near_eye_site_context_estimates.png" = "382a929e9ca5a9154fff3c509ba9bf116ebce00d61dd60227d559d10009872a8",
  "artifacts/10_figures/H03/H03_near_eye_site_context_estimates.pdf" = "d13a4daa0ddba02c308e297cd6f9d7b8eca8c6214d73a10a34063d3c064f85b0",
  "artifacts/10_figures/H03/H03_near_eye_site_context_estimates.svg" = "7b433203d57f2b7b91a0a46b8b187c89cc959a24146e3335e2c6e5d327ae7541",
  "artifacts/10_figures/H03/H03_reader_latitude_category_slopes.png" = "e27b7a8d84cabae1ab3e9694302a275da2f7bfd106df02a530a54ed48f5d9a15",
  "artifacts/10_figures/H03/H03_reader_latitude_category_slopes.pdf" = "d2db711358d6cdfd3f4c54e686449102208de48b2c325a35382f860f4253bfbe",
  "artifacts/10_figures/H03/H03_reader_latitude_category_slopes.svg" = "b994deeaa3c6335912cdc14ef0d53af932103091479d43d6665680320bfb75ec",
  "artifacts/11_source_data/H03/H03_near_eye_site_context_figure_data.csv" = "2d4ce68c9ac3fba8b31b5b7f190ee0f923ed1ba5d741045040cfde51e011f172",
  "artifacts/11_source_data/H03/H03_reader_latitude_figure_data.csv" = "30bb81bb176440368a45d8b3fd6e3fdc443a53d10eb440995cb0c904954536b2",
  "scripts/hypotheses/H03/h03_reporting.R" = "1412a89c52a5aa7d65559de5e2b927dcbaad64a990bffb11dc876e6fad6a2342",
  "scripts/hypotheses/H03/build_h03_stage3_revision.R" = "6d1eaacee852865b7b696653d0ee27cfd23d2001085aaf8612e2874521f87379"
)
stopifnot(all(vapply(
  names(baked_files),
  function(path) artifact_sha256(file.path(root, path)) == baked_files[[path]],
  logical(1L)
)))
site_svg <- collapse_source(read_source(file.path(
  root,
  "artifacts/10_figures/H03/H03_near_eye_site_context_estimates.svg"
)))
latitude_svg <- collapse_source(read_source(file.path(
  root,
  "artifacts/10_figures/H03/H03_reader_latitude_category_slopes.svg"
)))
stopifnot(
  grepl("BH", site_svg, fixed = TRUE),
  grepl("BH", latitude_svg, fixed = TRUE)
)

stage3_manifest <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/H03/H03_stage3_artifacts.csv"),
  show_col_types = FALSE
)
preparation_manifest <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H03/H03_preparation_report_manifest.csv"
  ),
  show_col_types = FALSE
)
manifest_paths <- unique(c(stage3_manifest$path, preparation_manifest$path))
absolute_manifest_paths <- file.path(root, manifest_paths)
stopifnot(all(file.exists(absolute_manifest_paths)))
current_manifest_hashes <- setNames(
  vapply(absolute_manifest_paths, artifact_sha256, character(1L)),
  manifest_paths
)
current_manifest_bytes <- setNames(
  file.info(absolute_manifest_paths)$size,
  manifest_paths
)
manifest_mismatches <- function(manifest) {
  sort(manifest$path[
    current_manifest_hashes[manifest$path] != manifest$sha256 |
      current_manifest_bytes[manifest$path] != manifest$bytes
  ])
}
stopifnot(identical(
  manifest_mismatches(stage3_manifest),
  "notebooks/hypotheses/H03.qmd"
))
expected_preparation_mismatches <- sort(c(
  "_build/nathealth/notebooks/hypotheses/H03.html",
  "_quarto-nathealth.yml",
  "artifacts/12_manifests/H03/H03_stage3_artifacts.csv",
  "audit/decisions/figure_readability_and_layout.md",
  "audit/hypotheses/H03/H03_analysis_preparation.qmd",
  "notebooks/hypotheses/H03.qmd",
  "tests/hypotheses/H03/test_h03_stage3_reader_report.R"
))
stopifnot(identical(
  manifest_mismatches(preparation_manifest),
  expected_preparation_mismatches
))

artifact_pattern <- "artifacts/[A-Za-z0-9_./-]+"
source_data_pattern <- "artifacts/11_source_data/[A-Za-z0-9_./-]+"
numeric_pattern <- "\\b[0-9]+(?:,[0-9]{3})*(?:\\.[0-9]+)?(?:e[+-]?[0-9]+)?\\b"
structural_hashes <- c(
  result_chunk_labels = set_sha256(names(result_chunks)),
  companion_chunk_labels = set_sha256(names(companion_chunks)),
  result_inline_r = set_sha256(extract_inline_r(result_text)),
  companion_inline_r = set_sha256(extract_inline_r(companion_text)),
  result_assignments = set_sha256(extract_top_assignments(result_chunks)),
  companion_assignments = set_sha256(extract_top_assignments(companion_chunks)),
  result_artifact_references = set_sha256(extract_pattern_set(
    result_text,
    artifact_pattern
  )),
  companion_artifact_references = set_sha256(extract_pattern_set(
    companion_text,
    artifact_pattern
  )),
  result_source_data_references = set_sha256(extract_pattern_set(
    result_text,
    source_data_pattern
  )),
  companion_source_data_references = set_sha256(extract_pattern_set(
    companion_text,
    source_data_pattern
  )),
  result_numeric_tokens = set_sha256(extract_pattern_set(
    result_text,
    numeric_pattern
  )),
  companion_numeric_tokens = set_sha256(extract_pattern_set(
    companion_text,
    numeric_pattern
  ))
)
expected_structural_hashes <- c(
  result_chunk_labels =
    "fc6fcf47a5c3a80ce44169892a01d54427ba2ba56ad88f22274e36b107e33b16",
  companion_chunk_labels =
    "9e02e82a4f1a69be0d9d1fbded49167404e7b864001016dbd64652b361c06661",
  result_inline_r =
    "ec8400f9edbf0bceba955643e65f42ba1ef3773e20120f9e5eb82e3e228745ed",
  companion_inline_r =
    "ffeaf5d26bf0e0505a26554cd0acd454d6b1f89eba2f54b97501020e744a4962",
  result_assignments =
    "73bbecfec7b0cea9b33eaa67d02c2f3a4b8b1d582b0e3a409c8f5793400f03d1",
  companion_assignments =
    "1290249989614dee5df6a34dd1269656d2d65a67a7c2c2a56307589dfb262e1d",
  result_artifact_references =
    "6a3beb08569722d3fdc1125761d0d2ea904f76e761e3d72a56bf19a67b15ee90",
  companion_artifact_references =
    "7c2ae4fbbec5f8f43811c73fc535fc2d12e45f63e8e9100201cc5c0d394742c2",
  result_source_data_references =
    "00810ec2e14d02c17ebe300a13fe503115efdb4c211cd8c2faba8104ded2b1d4",
  companion_source_data_references =
    "474d18f836df5c076b2e443f4cc09ebd5084a6803caba95e7ea093c73d4028b9",
  result_numeric_tokens =
    "a8fcd9b713419b7aeacd53a5355c6453c41b23295064fc63c0cd86c9847d6bab",
  companion_numeric_tokens =
    "6de1fdf5037798e905272c4673ccec06b9d4077d8fb3e1fe0447a3ddbd82bce8"
)
stopifnot(identical(structural_hashes, expected_structural_hashes))

stopifnot(
  artifact_sha256(result_path) ==
    "45ea5a009efd3b451c392dfc23bef584c7b16e087bf4093780b051cfde42ae41",
  artifact_sha256(companion_path) ==
    "59270288388e48ceef880ffa4a2ba0e87b8deeb9a8046b49510c4e525ff8c131"
)

message(
  "H03 REPORT-017 source harmonization checks passed under R ",
  as.character(getRversion()),
  ". No QMD was executed."
)
