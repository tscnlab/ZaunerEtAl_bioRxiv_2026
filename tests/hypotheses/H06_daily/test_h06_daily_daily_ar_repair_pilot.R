#!/usr/bin/env Rscript

# Focused no-refit verification of the bounded H06_daily AR-repair pilot.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  requireNamespace("digest", quietly = TRUE),
  requireNamespace("readr", quietly = TRUE)
)

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
read_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = "")
}
artifact <- function(stage, file) {
  file.path(root, "artifacts", stage, "H06_daily", file)
}
verify_manifest <- function(
  path,
  hash_column = "sha256",
  allowed_mismatch = character()
) {
  manifest <- read_csv(path)
  absolute <- file.path(root, manifest$relative_path)
  stopifnot(all(file.exists(absolute)))
  observed <- unname(vapply(absolute, sha256, character(1)))
  mismatched <- manifest$relative_path[observed != manifest[[hash_column]]]
  stopifnot(setequal(mismatched, allowed_mismatch))
  invisible(manifest)
}
normalize_formula <- function(formula) {
  gsub("[[:space:]]+", " ", paste(deparse(formula), collapse = " "))
}

input_manifest <- read_csv(artifact(
  "12_manifests",
  "H06_daily_stage2_daily_ar_repair_pilot_input_manifest.csv"
))
stopifnot(
  nrow(input_manifest) == 12L,
  all(input_manifest$verified),
  identical(input_manifest$expected_sha256, input_manifest$observed_sha256)
)
verify_manifest(
  artifact(
    "12_manifests",
    "H06_daily_stage2_daily_ar_repair_pilot_input_manifest.csv"
  ),
  "expected_sha256",
  c(
    "artifacts/12_manifests/base_model_data_artifacts.csv",
    paste0(
      "audit/hypotheses/H06_daily/",
      "H06_daily_mder_metric010_transition.md"
    )
  )
)
verify_manifest(artifact(
  "12_manifests",
  "H06_daily_stage2_daily_ar_repair_pilot_code_manifest.csv"
))
verify_manifest(artifact(
  "12_manifests",
  "H06_daily_stage2_daily_ar_repair_pilot_output_manifest.csv"
))
verify_manifest(file.path(
  root,
  "audit/hypotheses/H06_daily/",
  "H06_daily_daily_ar_repair_pilot_report_manifest.csv"
))

software <- read_csv(artifact(
  "12_manifests",
  "H06_daily_stage2_daily_ar_repair_pilot_software_manifest.csv"
))
observed_versions <- vapply(
  software$item[software$item != "R"],
  function(package) as.character(packageVersion(package)),
  character(1)
)
stopifnot(
  identical(
    unname(observed_versions),
    software$version[software$item != "R"]
  )
)

registry <- read_csv(artifact(
  "06_model_data",
  "H06_daily_stage2_daily_ar_repair_pilot_frame_registry.csv"
))
equivalence <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_stage2_daily_ar_repair_pilot_frame_equivalence.csv"
))
support <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_stage2_daily_ar_repair_pilot_support.csv"
))
diagnostics <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_stage2_daily_ar_repair_pilot_model_diagnostics.csv"
))
verdict <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_stage2_daily_ar_repair_pilot_verdict.csv"
))
effects <- read_csv(artifact(
  "09_tables",
  "H06_daily_stage2_daily_ar_repair_pilot_effect_stability.csv"
))
l10_audit <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_stage2_daily_ar_repair_pilot_l10_zero_mass_audit.csv"
))
l10_rows <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_stage2_daily_ar_repair_pilot_l10_near_zero_rows.csv"
))
models <- readRDS(artifact(
  "07_models",
  "H06_daily_stage2_daily_ar_repair_pilot_models.rds"
))

expected_repairs <- c("pre_sleep_identity", "l10_positive_magnitude")
stopifnot(
  identical(registry$repair_id, expected_repairs),
  nrow(equivalence) == 2L,
  all(equivalence$equivalence_pass),
  all(equivalence$old_normalized_sha256 ==
        equivalence$current_normalized_sha256),
  identical(as.integer(support$observations), c(648L, 680L)),
  identical(as.integer(support$participants), c(139L, 140L)),
  identical(as.integer(support$sites), c(9L, 9L)),
  identical(as.integer(support$adjacent_pairs), c(450L, 484L)),
  identical(
    as.integer(support$participants_with_adjacent_pair),
    c(130L, 126L)
  ),
  identical(as.integer(support$maximum_sequence_days), c(7L, 6L)),
  all(support$support_pass),
  identical(names(models$fits), expected_repairs)
)

for (i in seq_len(nrow(registry))) {
  frame <- readRDS(file.path(root, registry$frame_relative_path[[i]]))
  stopifnot(
    nrow(frame) == registry$observations[[i]],
    identical(sha256(file.path(root, registry$frame_relative_path[[i]])),
              registry$frame_sha256[[i]]),
    all(frame$date_gap[!frame$sequence_start] == 1L),
    all(frame$day_index[frame$sequence_start] == 1L),
    all(as.integer(as.character(frame$day_index_factor)) == frame$day_index)
  )
}

expected_pre_ar <- paste(
  "response_value ~ site + previous_sleep_duration_centered_h +",
  "(1 | participant_key) + ar1(day_index_factor + 0 | day_sequence_id)"
)
expected_l10_ar <- paste(
  "response_value ~ site + work_free_day + (1 | participant_key) +",
  "ar1(day_index_factor + 0 | day_sequence_id)"
)
stopifnot(
  identical(
    normalize_formula(models$fits$pre_sleep_identity$ar_formula),
    expected_pre_ar
  ),
  identical(
    normalize_formula(models$fits$l10_positive_magnitude$ar_formula),
    expected_l10_ar
  ),
  setequal(
    unique(diagnostics$model_id),
    c(
      "frozen_lmer_independent",
      "glmmTMB_independent",
      "glmmTMB_gap_aware_ar1"
    )
  ),
  nrow(diagnostics) == 6L,
  nrow(effects) == 6L
)

ar <- diagnostics[
  diagnostics$model_id == "glmmTMB_gap_aware_ar1",
  ,
  drop = FALSE
]
pre <- ar[ar$repair_id == "pre_sleep_identity", , drop = FALSE]
l10 <- ar[ar$repair_id == "l10_positive_magnitude", , drop = FALSE]
stopifnot(
  nrow(pre) == 1L,
  !pre$converged,
  !pre$positive_definite_hessian,
  !pre$singular,
  pre$warning_count == 2L,
  abs(pre$ar_rho - (-0.0847836)) < 1e-6,
  pre$residual_temporal_threshold_pass,
  pre$distribution_pass,
  pre$bounds_pass,
  nrow(l10) == 1L,
  !l10$converged,
  l10$positive_definite_hessian,
  l10$singular,
  l10$warning_count == 1L,
  l10$ar_rho > 0.999,
  !l10$residual_temporal_threshold_pass,
  !l10$distribution_pass,
  l10$bounds_pass
)

ar_effects <- effects[
  effects$model_id == "glmmTMB_gap_aware_ar1",
  ,
  drop = FALSE
]
stopifnot(
  all(ar_effects$direction_matches_frozen_lmer),
  abs(ar_effects$effect_shift_in_frozen_lmer_se[
    ar_effects$repair_id == "pre_sleep_identity"
  ] - 0.1296849) < 1e-6,
  abs(ar_effects$effect_shift_in_frozen_lmer_se[
    ar_effects$repair_id == "l10_positive_magnitude"
  ] - 0.8971440) < 1e-6,
  all(ar_effects$pilot_role ==
        "engineering family repair; no association claim")
)

overall <- verdict[verdict$domain == "Overall repair gate", , drop = FALSE]
pre_failed <- verdict$domain[
  verdict$repair_id == "pre_sleep_identity" &
    !verdict$passed &
    verdict$domain != "Overall repair gate"
]
l10_failed <- verdict$domain[
  verdict$repair_id == "l10_positive_magnitude" &
    !verdict$passed &
    verdict$domain != "Overall repair gate"
]
stopifnot(
  nrow(overall) == 2L,
  all(overall$verdict == "NOT_ACCEPTABLE"),
  identical(pre_failed, "AR numerical fit"),
  setequal(
    l10_failed,
    c(
      "AR numerical fit",
      "AR structured-covariance singularity",
      "AR coefficient",
      "Residual temporal dependence after AR",
      "Gaussian residual distribution"
    )
  )
)

stopifnot(
  l10_audit$participant_days == 784L,
  l10_audit$exact_zeros == 104L,
  l10_audit$positive_values_at_or_below_1e_12 == 3L,
  l10_audit$values_at_or_below_1e_12 == 107L,
  l10_audit$positive_component_rows == 680L,
  abs(l10_audit$positive_component_minimum_lx -
        4.163336342344337e-17) < 1e-30,
  nrow(l10_rows) == 3L,
  identical(l10_rows$Id, c("KNUST_S001", "KNUST_S005", "KNUST_S010")),
  identical(
    as.character(l10_rows$local_date),
    c("2024-10-13", "2024-11-08", "2024-12-14")
  ),
  all(l10_rows$l10_mean_medi_lx == 4.163336342344337e-17)
)

repair_outputs <- list.files(
  file.path(root, "artifacts"),
  pattern = "H06_daily_stage2_daily_ar_repair_pilot",
  recursive = TRUE,
  full.names = FALSE
)
stopifnot(
  !any(grepl("bootstrap|simulation|deletion", repair_outputs, ignore.case = TRUE))
)

qmd_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/06_daily_ar_repair_pilot.qmd"
)
html_path <- sub("[.]qmd$", ".html", qmd_path)
transition_path <- file.path(
  root,
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_daily_ar_repair_pilot_transition.md"
  )
)
stopifnot(file.exists(qmd_path), file.exists(html_path), file.exists(transition_path))
qmd_text <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
html_text <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
transition_text <- paste(readLines(transition_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("H06-D-G2P-AR", qmd_text, fixed = TRUE),
  grepl("H06-D-G2P-AR", html_text, fixed = TRUE),
  grepl("H06-D-G2P-AR", transition_text, fixed = TRUE),
  grepl("no association claim", html_text, ignore.case = TRUE),
  grepl("NOT_ACCEPTABLE", html_text, fixed = TRUE),
  !grepl("math display", html_text, ignore.case = TRUE)
)

message(
  "H06_daily bounded AR-repair pilot verification passed: ",
  "two frozen/current-equivalent frames, two NOT_ACCEPTABLE AR repairs, ",
  "three L10 numerical-near-zero positive rows, no refit."
)
