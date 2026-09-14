#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
stopifnot(length(file_arg) == 1L)
script_path <- sub("^--file=", "", file_arg)
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
qmd_path <- file.path(
  root,
  "notebooks/preparation/04_metric_derivation.qmd"
)
lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")

fail <- function(message) stop(message, call. = FALSE)
expect_true <- function(condition, message) {
  if (!isTRUE(condition)) fail(message)
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
      fail(paste("Unclosed R chunk beginning at line", index))
    }
    end <- end_candidates[1]
    chunks[[length(chunks) + 1L]] <- list(
      start = index,
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

chunks <- extract_r_chunks(lines)
expect_true(length(chunks) == 16L, "Expected exactly 16 bounded R chunks.")
for (chunk in chunks) {
  code <- chunk$code[!grepl("^[[:space:]]*#\\|", chunk$code)]
  parsed <- try(parse(text = paste(code, collapse = "\n")), silent = TRUE)
  expect_true(
    !inherits(parsed, "try-error"),
    paste("R syntax failed in chunk beginning at line", chunk$start)
  )
}

executable <- paste(
  unlist(lapply(chunks, `[[`, "code"), use.names = FALSE),
  collapse = "\n"
)
forbidden <- c(
  "\\bbuild_[A-Za-z0-9_.]+[[:space:]]*\\(",
  "\\bverify_[A-Za-z0-9_.]+[[:space:]]*\\(",
  "\\bsource[[:space:]]*\\(",
  "\\b(write_[A-Za-z0-9_.]+|write\\.(csv|table)|writeLines)[[:space:]]*\\(",
  "\\b(saveRDS|save|dir\\.create|file\\.create|file\\.copy|unlink)[[:space:]]*\\(",
  "\\b(download\\.file|curl_fetch|GET|POST|system|system2)[[:space:]]*\\(",
  paste0(
    "\\b(lm|glm|gam|bam|lmer|glmer|glmmTMB|predict|acf|simulate|boot|",
    "bootstrap|shapley)[A-Za-z0-9_.]*[[:space:]]*\\("
  )
)
for (pattern in forbidden) {
  expect_true(
    !grepl(pattern, executable, perl = TRUE, ignore.case = TRUE),
    paste("Forbidden executable pattern:", pattern)
  )
}

full <- paste(lines, collapse = "\n")
visible <- strip_fenced_blocks(lines)
visible_no_code <- gsub("`[^`]*`", "", visible)
visible_flat <- gsub("[[:space:]]+", " ", visible)

expect_true(
  grepl(
    'title="What is calculated during this render?"',
    full,
    fixed = TRUE
  ),
  "Missing render-boundary note."
)
expect_true(!grepl("knitr::kable", full, fixed = TRUE), "kable remains.")
expect_true(grepl("library(gt)", executable, fixed = TRUE), "gt is not loaded.")
expect_true(grepl("melEDI", visible, fixed = TRUE), "melEDI is absent.")
expect_true(
  !grepl("\\bbout(s)?\\b", visible_no_code, perl = TRUE, ignore.case = TRUE),
  "Use period, not bout."
)
expect_true(
  !grepl(
    "\\b(V0|legacy|previous|canonical)\\b|manuscript-prepared",
    visible_no_code,
    perl = TRUE,
    ignore.case = TRUE
  ),
  "Forbidden reader-facing workflow label remains."
)

expect_true(
  grepl("gap-timing-unaware dataset", visible, fixed = TRUE),
  "Approved prepared-data sensitivity term is absent."
)
expect_true(
  grepl("50%-per-hour", visible, fixed = TRUE) &&
    grepl("80%-per-day", visible, fixed = TRUE) &&
    grepl(
      "timing of remaining[[:space:]]+missing observations was not used",
      visible,
      perl = TRUE
    ),
  "The first-use explanation of the gap-timing-unaware dataset is incomplete."
)
expect_true(
  grepl("time-sensitive primary metric dataset", visible, fixed = TRUE),
  "The permitted first-use contrast is absent."
)

current_hashes <- c(
  "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
  "7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43",
  "5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb",
  "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935",
  "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
  "a0bc5d7ea2142709412da2253158086416ddb730b0f60ff616bba9d6ccb1edc5",
  "81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018",
  "9ca9b97dac5efd9ec4e7b43a1fb2227b7a13cf98ac4b92318606c4874f9e460b",
  "755508076e42ed74ce0d40f48de192b69ea81b04532db2d5a950c451236e2619",
  "1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de",
  "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
  "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb"
)
for (hash in current_hashes) {
  expect_true(grepl(hash, full, fixed = TRUE), paste("Missing hash:", hash))
}
expect_true(grepl("PREP-003", visible, fixed = TRUE), "PREP-003 is absent.")
expect_true(grepl("FIND-044", visible, fixed = TRUE), "FIND-044 is absent.")
expect_true(
  grepl("sole Preparation 04 item", full, fixed = TRUE) &&
    grepl("does not apply to current MDER", visible_flat, fixed = TRUE),
  "The resolved MDER and open diary-period verification boundary is absent."
)
expect_true(
  grepl("not evidence", visible, fixed = TRUE) &&
    grepl("downstream", visible, fixed = TRUE),
  "The open audit item lacks its non-discrepancy qualification."
)

mder_contract <- c(
  "arithmetic mean of the viable one-minute melEDI/illuminance ratios",
  "both channels are finite and strictly greater than zero",
  "complete 1,440-position local wall-clock grid",
  "averaged within that clock minute before their ratio is formed",
  "does not exist during the spring clock change remains missing",
  "At least 720 of the 1,440 positions must be viable",
  "the boundary is inclusive",
  "only MDER is unavailable",
  "not a ratio of daily channel integrals",
  "profile-supported ratio-of-integrals method",
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
  "25,620 non-MDER participant-day cells exactly unchanged"
)
for (token in mder_contract) {
  expect_true(
    grepl(token, visible_flat, fixed = TRUE),
    paste("Missing MDER rule:", token)
  )
}
expect_true(
  grepl(
    "earlier 725/729 availability record is superseded",
    full,
    fixed = TRUE
  ),
  "The superseded MDER availability record is absent from table source."
)

l10_contract <- c(
  "adds 0.1 lx",
  "averages on the log10 scale",
  "transforms back",
  "every finite source minute is itself exactly zero",
  "Missing minutes remain missing",
  "4.163336342344337e-17",
  "2.220446049250313e-14",
  "Exactly eight primary L10 mean cells changed",
  "three near-eye and five chest",
  "547 observed zero minutes and 53 missing minutes",
  "all 816 near-eye and 902 chest participant-days",
  "four previously documented negative roundoff residuals",
  "Every non-L10 value and all samples are unchanged",
  "No hypothesis model is run"
)
for (token in l10_contract) {
  expect_true(
    grepl(token, visible_flat, fixed = TRUE),
    paste("Missing METRIC-011 reporting rule:", token)
  )
}
expect_true(
  !grepl("current 80% gate retains 760", visible, fixed = TRUE) &&
    !grepl("MDER is an unscaled ratio", visible, fixed = TRUE),
  "A superseded MDER claim remains active in visible prose."
)

table_chunks <- Filter(
  function(chunk) any(grepl("^#\\| label: tbl-", chunk$code)),
  chunks
)
expect_true(length(table_chunks) == 14L, "Expected exactly 14 gt tables.")
for (chunk in table_chunks) {
  expect_true(
    any(grepl("^#\\| tbl-cap: ", chunk$code)),
    paste("Missing table caption at line", chunk$start)
  )
  expect_true(
    any(grepl("prep_gt[[:space:]]*\\(", chunk$code)),
    paste("Table is not built with gt at line", chunk$start)
  )
}
expect_true(
  grepl("`Step and producing code` ~ gt::pct(38)", full, fixed = TRUE) &&
    grepl(
      "`Reads, operation, separation, and output` ~ gt::pct(62)",
      full,
      fixed = TRUE
    ),
  "The script map is not the approved two-column layout."
)

required_paths <- c(
  "artifacts/12_manifests/metric_artifacts.csv",
  "artifacts/12_manifests/mder_support_gate_artifacts.csv",
  "artifacts/12_manifests/state_support_gate_artifacts.csv",
  "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
  "artifacts/05_metrics/metric_derivation_settings.csv",
  "artifacts/05_metrics/state_support_candidate_diagnostics.csv",
  "artifacts/08_diagnostics/mder_METRIC-010/audit_manifest.csv",
  "artifacts/08_diagnostics/mder_METRIC-010/verification_summary.csv",
  "artifacts/08_diagnostics/mder_METRIC-010/distribution_summary.csv",
  "artifacts/08_diagnostics/mder_METRIC-010/support_by_site.csv",
  "artifacts/08_diagnostics/mder_METRIC-010/paired_comparisons.csv",
  "artifacts/08_diagnostics/mder_METRIC-010/key_level_comparison.csv",
  "artifacts/08_diagnostics/mder_METRIC-010/non_mder_invariance.csv",
  "audit/reconciliation/mder_METRIC-010_gap_repair/gap_repair_evidence_manifest.csv",
  "audit/reconciliation/mder_METRIC-010_gap_repair/gap_mder_summary.csv",
  "audit/reconciliation/mder_METRIC-010_gap_repair/gap_mder_support_summary.csv",
  "audit/reconciliation/mder_METRIC-010_gap_repair/gap_non_mder_invariance.csv",
  "audit/reconciliation/mder_METRIC-010_gap_repair/gap_repair_input_output_hashes.csv",
  "artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds",
  "artifacts/06_model_data/scenarios/manuscript_prepared_data/mder_support.rds",
  "audit/decisions/mder_mean_of_viable_ratios.md",
  "audit/decisions/l10_numerical_zero_normalization.md",
  "audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv",
  "audit/reconciliation/l10_METRIC-011/all_numerical_zero_reclassifications.csv",
  "audit/reconciliation/l10_METRIC-011/positive_roundoff_reclassifications.csv",
  "audit/reconciliation/l10_METRIC-011/primary_scientific_cell_changes.csv",
  "audit/reconciliation/l10_METRIC-011/manifest_transition.csv",
  "audit/reconciliation/l10_METRIC-011/invariance_summary.csv",
  "artifacts/05_metrics/metrics_glasses_admissibility.csv",
  "artifacts/05_metrics/metrics_chest_admissibility.csv",
  "artifacts/05_metrics/metrics_glasses_gap_diagnostics.csv",
  "artifacts/05_metrics/metrics_chest_gap_diagnostics.csv"
)
for (path in required_paths) {
  expect_true(grepl(path, full, fixed = TRUE), paste("Missing path:", path))
}
required_scripts <- c(
  "scripts/pipeline/build_metric_derivation.R",
  "scripts/pipeline/metric_derivation.R",
  "scripts/pipeline/state_interval_projection.R",
  "scripts/pipeline/time_support.R",
  "scripts/pipeline/verify_metric_derivation_core.R",
  "scripts/pipeline/verify_metric_derivation_mder.R",
  "audit/scripts/finalize_mder_METRIC_010.R",
  "audit/scripts/repair_gap_mder_METRIC_010.R",
  "audit/scripts/finalize_gap_mder_METRIC_010_evidence.R",
  "audit/scripts/finalize_l10_METRIC_011.R"
)
for (path in required_scripts) {
  expect_true(grepl(path, full, fixed = TRUE), paste("Missing script:", path))
}

expect_true(
  grepl("#| label: fig-mder-availability", full, fixed = TRUE),
  "Missing empirical figure."
)
expect_true(grepl("#| fig-cap:", full, fixed = TRUE), "Missing figure caption.")
expect_true(grepl("#| fig-alt:", full, fixed = TRUE), "Missing figure alt text.")
expect_true(grepl("#| fig-width: 7.2", full, fixed = TRUE), "Wrong figure width.")
expect_true(grepl("#| fig-height: 4.2", full, fixed = TRUE), "Wrong figure height.")
expect_true(
  grepl("axis.text = element_text(size = 9", full, fixed = TRUE),
  "Axis text is below the REPORT-011 plan."
)
expect_true(
  grepl("legend.text = element_text(size = 9", full, fixed = TRUE),
  "Legend text is below the REPORT-011 plan."
)
expect_true(
  grepl(
    "[Download the source data for @fig-mder-availability](../../artifacts/08_diagnostics/mder_METRIC-010/verification_summary.csv)",
    full,
    fixed = TRUE
  ),
  "The empirical figure lacks its paired source-data link."
)

if (length(args) >= 1L) {
  html_path <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
  html <- paste(
    readLines(html_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  required_html <- c(
    "Preparation 04: Derive light-exposure metrics",
    "fig-mder-availability",
    "tbl-current-manifest-validation",
    "tbl-version-specific-verification",
    "tbl-l10-numerical-zero",
    "FIND-044",
    "gap-timing-unaware dataset",
    "verification_summary.csv",
    "METRIC-010",
    "METRIC-011",
    "earlier 725/729 availability record is superseded",
    "547 observed zero minutes and 53 missing minutes"
  )
  for (token in required_html) {
    expect_true(grepl(token, html, fixed = TRUE), paste("HTML lacks:", token))
  }
  expect_true(!grepl("# A tibble:", html, fixed = TRUE), "Raw tibble output is visible.")
}

cat(
  paste0(
    "PASS: Preparation 04 satisfies the bounded-render, version-specific ",
    "verification, gt-table, figure, terminology, and provenance contract.\n"
  )
)
