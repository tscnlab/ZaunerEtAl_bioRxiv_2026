#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
root <- normalizePath(
  file.path(dirname(commandArgs(trailingOnly = FALSE)[1]), ".."),
  winslash = "/",
  mustWork = TRUE
)

# Rscript reports the script path as --file=... rather than as argv[1].
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(file_arg) == 1L) {
  script_path <- sub("^--file=", "", file_arg)
  root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
}

qmd_path <- file.path(
  root,
  "notebooks/preparation/06_model_ready_datasets.qmd"
)
stopifnot(file.exists(qmd_path))
lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")

fail <- function(message) {
  stop(message, call. = FALSE)
}

expect_true <- function(condition, message) {
  if (!isTRUE(condition)) {
    fail(message)
  }
}

count_fixed <- function(text, pattern) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1]]
  if (identical(matches, -1L)) 0L else length(matches)
}

extract_r_chunks <- function(source_lines) {
  chunks <- list()
  index <- 1L
  while (index <= length(source_lines)) {
    if (!grepl("^```\\{r(?:[,}])", source_lines[index], perl = TRUE)) {
      index <- index + 1L
      next
    }
    end_candidates <- which(
      seq_along(source_lines) > index &
        grepl("^```[[:space:]]*$", source_lines)
    )
    if (length(end_candidates) == 0L) {
      fail(paste0("Unclosed R chunk beginning at line ", index, "."))
    }
    end <- end_candidates[1]
    chunks[[length(chunks) + 1L]] <- list(
      start = index,
      end = end,
      code = source_lines[seq.int(index + 1L, end - 1L)]
    )
    index <- end + 1L
  }
  chunks
}

strip_fenced_blocks <- function(source_lines) {
  keep <- character()
  inside <- FALSE
  for (line in source_lines) {
    if (grepl("^```", line)) {
      inside <- !inside
    } else if (!inside) {
      keep <- c(keep, line)
    }
  }
  paste(keep, collapse = "\n")
}

r_chunks <- extract_r_chunks(lines)
expect_true(length(r_chunks) >= 15L, "Expected at least 15 bounded R chunks.")

for (chunk in r_chunks) {
  code_lines <- chunk$code[!grepl("^[[:space:]]*#\\|", chunk$code)]
  code_text <- paste(code_lines, collapse = "\n")
  parse_result <- try(parse(text = code_text), silent = TRUE)
  expect_true(
    !inherits(parse_result, "try-error"),
    paste0("R syntax failed in chunk beginning at line ", chunk$start, ".")
  )
}

executable_code <- paste(
  unlist(lapply(r_chunks, function(chunk) chunk$code), use.names = FALSE),
  collapse = "\n"
)

forbidden_executable_patterns <- c(
  "\\bbuild_[A-Za-z0-9_.]+[[:space:]]*\\(",
  "\\bverify_[A-Za-z0-9_.]+[[:space:]]*\\(",
  "\\bsource[[:space:]]*\\(",
  "\\b(write_[A-Za-z0-9_.]+|write\\.(csv|table)|writeLines)[[:space:]]*\\(",
  "\\b(saveRDS|save|dir\\.create|file\\.create|file\\.copy|file\\.rename|unlink)[[:space:]]*\\(",
  "\\b(download\\.file|curl_fetch|GET|POST|system|system2)[[:space:]]*\\(",
  "\\b(lm|glm|gam|bam|lmer|glmer|glmmTMB)[[:space:]]*\\(",
  "\\b(predict|acf|simulate|boot|bootstrap|shapley)[A-Za-z0-9_.]*[[:space:]]*\\(",
  "\\bquarto_render[[:space:]]*\\("
)

for (pattern in forbidden_executable_patterns) {
  expect_true(
    !grepl(pattern, executable_code, perl = TRUE, ignore.case = TRUE),
    paste0("Forbidden executable pattern in Preparation 06: ", pattern)
  )
}

full_source <- paste(lines, collapse = "\n")
visible_prose <- strip_fenced_blocks(lines)
visible_without_inline_code <- gsub("`[^`]*`", "", visible_prose)
visible_flat <- gsub("[[:space:]]+", " ", visible_prose)

expect_true(
  grepl(
    "The predefined **gap-timing-unaware dataset** still passed the general",
    visible_prose,
    fixed = TRUE
  ),
  "Missing the approved first-use dataset explanation."
)
expect_true(
  grepl(
    "50%-per-hour and 80%-per-day coverage rules",
    visible_prose,
    fixed = TRUE
  ),
  "Missing the general coverage rules in the first explanation."
)
expect_true(
  grepl(
    "remaining missing observations was not used for an additional metric-specific",
    visible_prose,
    fixed = TRUE
  ),
  "Missing the meaning of gap-timing-unaware."
)
expect_true(
  count_fixed(full_source, "time-sensitive primary metric dataset") == 1L,
  "The one-time primary-dataset interpretation must occur exactly once."
)
expect_true(
  !grepl(
    "\\b(V0|legacy|previous|canonical)\\b",
    visible_without_inline_code,
    perl = TRUE,
    ignore.case = TRUE
  ),
  "A forbidden visible scenario/workflow label remains."
)
expect_true(
  !grepl("manuscript-prepared", visible_without_inline_code, ignore.case = TRUE),
  "The historical scenario label remains in visible prose."
)
expect_true(
  !grepl("\\bbout(s)?\\b", visible_without_inline_code, perl = TRUE, ignore.case = TRUE),
  "Reader-facing prose must use period rather than bout."
)
expect_true(grepl("melEDI", visible_prose, fixed = TRUE), "melEDI terminology is absent.")

mder_contract <- c(
  "arithmetic mean of viable one-minute melEDI/illuminance ratios",
  "complete 1,440-position local wall-clock grid",
  "Both channels must be finite and strictly greater than zero",
  "two channels are averaged separately within that clock minute",
  "absent spring-forward minute remains missing",
  "At least 720 viable ratios are required",
  "exactly 720 passes the inclusive 50% rule",
  "makes MDER alone unavailable",
  "not a ratio of daily integrals",
  "The older ratio-of-integrals and profile-based exclusion records document an earlier method and are not active.",
  "702 of 816",
  "732 of 902",
  "137 participants",
  "152 participants",
  "mean 0.7239; median 0.7239",
  "mean 0.7565; median",
  "687 of 811",
  "723 of 897",
  "mean 0.7243; median",
  "mean 0.7567; median",
  "The stored comparison found all 25,620 non-MDER participant-day cells exactly unchanged and retained all 618 × 47 site/daylight context values exactly.",
  "618 × 47",
  "site/daylight context values exactly"
)
for (token in mder_contract) {
  expect_true(
    grepl(token, visible_flat, fixed = TRUE),
    paste("Missing MDER reporting contract:", token)
  )
}
expect_true(
  !grepl("MDER is an unscaled ratio", visible_flat, fixed = TRUE) &&
    !grepl("current 80% gate", visible_flat, fixed = TRUE),
  "A superseded MDER statement remains active."
)

expect_true(
  grepl(
    '::: {.callout-note appearance="simple" title="What is calculated during this render?"}',
    full_source,
    fixed = TRUE
  ),
  "Missing the informational render-boundary note."
)
expect_true(!grepl("knitr::kable", full_source, fixed = TRUE), "kable remains in the report.")
expect_true(grepl("library(gt)", executable_code, fixed = TRUE), "gt is not loaded.")
expect_true(
  grepl("`Step and producing code` ~ gt::pct(38)", full_source, fixed = TRUE) &&
    grepl(
      "`Reads, operation, separation, and output` ~ gt::pct(62)",
      full_source,
      fixed = TRUE
    ),
  "The script execution map must retain its approved two-column layout."
)
expect_true(
  grepl(
    '"Verify repaired gap-timing-unaware MDER"',
    full_source,
    fixed = TRUE
  ) &&
    grepl(
      '"Record the preceding MDER repin and invariance"',
      full_source,
      fixed = TRUE
    ) &&
    grepl(
      '"Verify and reseal numerical-zero normalization"',
      full_source,
      fixed = TRUE
    ),
  "The repaired-MDER or METRIC-011 provenance steps lack reader-facing stage labels."
)

l10_contract <- c(
  "L10 is the mean melEDI during the darkest 10-hour window",
  "adds 0.1 lx",
  "averages `log10(melEDI + 0.1)`",
  "every finite source minute is exactly zero",
  "Missing minutes remain missing",
  "4.163336342344337e-17",
  "2.220446049250313e-14",
  "Exactly eight primary L10 mean cells changed",
  "three near-eye and five chest",
  "547 observed zero minutes and 53 missing minutes",
  "All 816 near-eye and 902 chest participant-days remain",
  "Every non-L10 scientific value, every sample definition, all 30-minute and hourly values",
  "all gap-timing-unaware scientific values are unchanged",
  "No hypothesis model was fitted or refitted"
)
for (token in l10_contract) {
  expect_true(
    grepl(token, visible_flat, fixed = TRUE),
    paste("Missing METRIC-011 reporting contract:", token)
  )
}

table_chunks <- Filter(
  function(chunk) any(grepl("^#\\| label: tbl-", chunk$code)),
  r_chunks
)
expect_true(length(table_chunks) >= 12L, "Expected at least 12 reader-facing tables.")
for (chunk in table_chunks) {
  expect_true(
    any(grepl("^#\\| tbl-cap: ", chunk$code)),
    paste0("Table chunk at line ", chunk$start, " lacks a Quarto caption.")
  )
  expect_true(
    any(grepl("prep_gt[[:space:]]*\\(", chunk$code)),
    paste0("Table chunk at line ", chunk$start, " is not a gt table.")
  )
}

required_paths <- c(
  "artifacts/12_manifests/model_input_normalization.csv",
  "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
  "artifacts/12_manifests/site_solar_context_artifacts.csv",
  "artifacts/06_model_data/temporal_provenance/artifact_manifest.csv",
  "artifacts/12_manifests/base_model_data_artifacts.csv",
  "artifacts/12_manifests/H01_model_data_artifacts.csv",
  "artifacts/12_manifests/H01_manuscript_prepared_data_artifacts.csv",
  "artifacts/12_manifests/preanalysis_comparison_artifacts.csv",
  "artifacts/12_manifests/metric_artifacts.csv",
  "artifacts/12_manifests/mder_support_gate_artifacts.csv",
  "artifacts/08_diagnostics/mder_METRIC-010/audit_manifest.csv",
  "artifacts/08_diagnostics/mder_METRIC-010/verification_summary.csv",
  "artifacts/08_diagnostics/mder_METRIC-010/distribution_summary.csv",
  "artifacts/08_diagnostics/mder_METRIC-010/non_mder_invariance.csv",
  "audit/reconciliation/mder_METRIC-010_gap_repair/gap_repair_evidence_manifest.csv",
  "audit/reconciliation/mder_METRIC-010_gap_repair/gap_mder_summary.csv",
  "audit/reconciliation/mder_METRIC-010_gap_repair/gap_mder_support_summary.csv",
  "audit/reconciliation/mder_METRIC-010_gap_repair/gap_non_mder_invariance.csv",
  "audit/reconciliation/mder_METRIC-010_gap_repair/gap_repair_input_output_hashes.csv",
  "artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds",
  "artifacts/06_model_data/scenarios/manuscript_prepared_data/mder_support.rds",
  "artifacts/08_diagnostics/mder_METRIC-010/downstream_rebuild/rebuild_manifest.csv",
  "artifacts/08_diagnostics/mder_METRIC-010/downstream_rebuild/site_context_value_check.csv",
  "artifacts/08_diagnostics/mder_METRIC-010/downstream_rebuild/manifest_comparison.csv",
  "audit/decisions/l10_numerical_zero_normalization.md",
  "audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv",
  "audit/reconciliation/l10_METRIC-011/all_numerical_zero_reclassifications.csv",
  "audit/reconciliation/l10_METRIC-011/positive_roundoff_reclassifications.csv",
  "audit/reconciliation/l10_METRIC-011/primary_scientific_cell_changes.csv",
  "audit/reconciliation/l10_METRIC-011/manifest_transition.csv",
  "audit/reconciliation/l10_METRIC-011/invariance_summary.csv",
  "artifacts/06_model_data/base/metrics_glasses_participant_day_context.rds",
  "artifacts/06_model_data/base/metrics_chest_participant_day_context.rds",
  "audit/decisions/mder_mean_of_viable_ratios.md",
  "audit/decisions/preparation06_current_base_model_gate.md"
)
for (path in required_paths) {
  expect_true(grepl(path, full_source, fixed = TRUE), paste("Missing path:", path))
}

required_scripts <- c(
  "scripts/pipeline/build_metric_derivation.R",
  "scripts/pipeline/metric_derivation.R",
  "scripts/pipeline/time_support.R",
  "scripts/pipeline/verify_metric_derivation_mder.R",
  "scripts/pipeline/verify_metric_derivation_core.R",
  "audit/scripts/finalize_mder_METRIC_010.R",
  "audit/scripts/repair_gap_mder_METRIC_010.R",
  "audit/scripts/finalize_gap_mder_METRIC_010_evidence.R",
  "audit/scripts/rebuild_mder_METRIC_010_downstream.R",
  "audit/scripts/finalize_l10_METRIC_011.R",
  "scripts/pipeline/build_model_input_normalization.R",
  "scripts/pipeline/build_manuscript_prepared_data.R",
  "scripts/pipeline/build_site_solar_context.R",
  "scripts/pipeline/build_temporal_sequence_provenance.R",
  "scripts/pipeline/build_base_model_data.R",
  "scripts/pipeline/build_h01_model_data.R",
  "scripts/pipeline/build_h01_manuscript_prepared_data.R",
  "scripts/pipeline/build_preanalysis_comparison.R"
)
for (path in required_scripts) {
  expect_true(grepl(path, full_source, fixed = TRUE), paste("Missing script:", path))
}

required_hashes <- c(
  "e3d484711abb54f69d63ff302e5a0329efda3fd0a8c85feaf9cc4f850005c9ab",
  "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935",
  "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518",
  "9355f7ca4f249059cf49808a3fb1caf9e764a6160f5d61beba8234a2bfbdef7d",
  "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce",
  "25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72",
  "e0d98178ede61b74353e3a654e7f1b53d7e1c915833a2cda74eea45ed02f383b",
  "f3c4bfbf120d2023c045b44e3c7c04c58bce1f8d11621956bca1e5ede90c5623",
  "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
  "7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43",
  "5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb",
  "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
  "a0bc5d7ea2142709412da2253158086416ddb730b0f60ff616bba9d6ccb1edc5",
  "81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018",
  "408087d420999322628066caae31efc288a5a5213b8b57d4b9a4ad77c9ec9a77",
  "e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916",
  "013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a",
  "497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057",
  "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
  "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
  "1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de",
  "63f17f1b9b3a91d437a5964cde063770d0fb4fac3f9c81e588fc374d9cc71f04",
  "9ca9b97dac5efd9ec4e7b43a1fb2227b7a13cf98ac4b92318606c4874f9e460b"
)
for (hash in required_hashes) {
  expect_true(grepl(hash, full_source, fixed = TRUE), paste("Missing hash:", hash))
}
expect_true(
  grepl("~stage_order, ~stage, ~manifest, ~expected_sha256", full_source, fixed = TRUE),
  "The eight manifest files are not pinned to expected identities."
)

expect_true(grepl("#| label: fig-site-composition", full_source, fixed = TRUE), "Missing figure label.")
expect_true(grepl("#| fig-cap:", full_source, fixed = TRUE), "Missing figure caption.")
expect_true(grepl("#| fig-alt:", full_source, fixed = TRUE), "Missing figure alt text.")
expect_true(grepl("#| fig-width: 7.5", full_source, fixed = TRUE), "Unexpected figure width.")
expect_true(grepl("#| fig-height: 6.8", full_source, fixed = TRUE), "Unexpected figure height.")
expect_true(grepl("axis.text = element_text(size = 9", full_source, fixed = TRUE), "Axis text is below the planned size.")
expect_true(grepl("strip.text = element_text(size = 10", full_source, fixed = TRUE), "Facet text is below the planned size.")
expect_true(grepl("config/site_display_registry.csv", full_source, fixed = TRUE), "Site display registry is not used.")
expect_true(grepl("scale_fill_manual", executable_code, fixed = TRUE), "Registered site colours are not applied.")
expect_true(
  grepl(
    "[Download the source data for @fig-site-composition](../../artifacts/08_diagnostics/preanalysis_comparison/categorical_levels.csv)",
    full_source,
    fixed = TRUE
  ),
  "The figure lacks its paired source-data link."
)
expect_true(
  !grepl("categorical_distribution_overview.png", full_source, fixed = TRUE),
  "The old figure with historical visible labels remains embedded."
)
expect_true(grepl("Its final-display check covers", visible_flat, fixed = TRUE), "Reader-facing final-display QA statement is absent.")

if (length(args) >= 1L) {
  html_path <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
  html <- paste(readLines(html_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  required_html_tokens <- c(
    "Preparation 06: Build model-ready datasets",
    "fig-site-composition",
    "tbl-manifest-identity",
    "tbl-script-execution-map",
    "tbl-current-mder-availability",
    "tbl-current-mder-provenance",
    "tbl-l10-zero-handoff",
    "tbl-l10-preparation-provenance",
    "categorical_levels.csv",
    "gap-timing-unaware dataset",
    "METRIC-010",
    "METRIC-011"
  )
  for (token in required_html_tokens) {
    expect_true(grepl(token, html, fixed = TRUE), paste("Rendered HTML lacks:", token))
  }
  expect_true(
    !grepl("<strong>12. NA</strong>|<strong>13. NA</strong>", html, perl = TRUE),
    "The rendered script execution map contains an unlabeled provenance step."
  )
  expect_true(!grepl("# A tibble:", html, fixed = TRUE), "Raw tibble output is visible in HTML.")
  expect_true(!grepl("manuscript-prepared", html, ignore.case = TRUE), "Historical scenario label is visible in HTML.")
}

cat(
  "PASS: Preparation 06 source satisfies the bounded-render, terminology, gt-table, figure, and provenance contract.\n"
)
