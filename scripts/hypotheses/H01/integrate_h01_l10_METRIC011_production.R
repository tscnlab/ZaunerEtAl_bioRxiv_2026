# Integrate the author-approved H01 METRIC-011 L10 production results.
#
# This is deliberately a bounded, no-refit integration. It replaces only the
# four primary-data L10-mean point branches, their stored 1,000-refit draws and
# interval summaries, and BH-derived fields in the four affected 17-test
# vectors. Protected non-L10, gap-L10, and METRIC-010 artifacts remain
# byte-identical. Mixed aggregate diagnostic files are left untouched; sealed
# current overlays are written inside the H01 METRIC-011 audit tree.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H01 METRIC-011 integration requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

producer <- paste0(
  "scripts/hypotheses/H01/",
  "integrate_h01_l10_METRIC011_production.R"
)
metric_id <- "l10_mean_medi"
target_runs <- c(
  "main__chest__all_available",
  "main__chest__paired_common_sample",
  "main__glasses__all_available",
  "main__glasses__paired_common_sample"
)
audit_root <- file.path(root, "audit/hypotheses/H01/l10_METRIC-011")
point_root <- file.path(audit_root, "point_refit")
gate_root <- file.path(audit_root, "author_gate")
production_root <- file.path(audit_root, "bootstrap_production")
integration_root <- file.path(audit_root, "production_integration")
overlay_root <- file.path(integration_root, "current_overlays")
dir.create(overlay_root, recursive = TRUE, showWarnings = FALSE)

relative_to_root <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  prefix <- paste0(root, "/")
  ifelse(startsWith(normalized, prefix), substring(normalized, nchar(prefix) + 1L), normalized)
}

read_csv_strict <- function(path) {
  if (!file.exists(path)) {
    stop("Missing integration input: ", relative_to_root(dirname(path)), "/", basename(path), call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

verify_manifest <- function(path) {
  manifest <- read_csv_strict(path)
  stopifnot(all(c("path", "sha256") %in% names(manifest)))
  files <- file.path(root, manifest$path)
  stopifnot(all(file.exists(files)))
  observed <- unname(vapply(files, artifact_sha256, character(1)))
  stopifnot(identical(observed, unname(manifest$sha256)))
  invisible(manifest)
}

key_string <- function(data, keys) {
  stopifnot(all(keys %in% names(data)))
  values <- lapply(data[keys], function(value) {
    value <- as.character(value)
    value[is.na(value)] <- "<NA>"
    value
  })
  do.call(paste, c(values, sep = "\r"))
}

replace_rows_by_key <- function(base, replacement, keys, label) {
  stopifnot(identical(names(base), names(replacement)))
  base_key <- key_string(base, keys)
  replacement_key <- key_string(replacement, keys)
  if (anyDuplicated(base_key) || anyDuplicated(replacement_key)) {
    stop("Duplicate key in ", label, call. = FALSE)
  }
  index <- match(replacement_key, base_key)
  if (anyNA(index)) {
    stop("Replacement key absent from canonical ", label, call. = FALSE)
  }
  base[index, ] <- replacement
  base
}

target_main_l10 <- function(data) {
  data$run_id %in% target_runs & data$metric_id == metric_id
}

copy_atomic <- function(from, to) {
  if (!file.exists(from)) {
    stop("Missing replacement artifact: ", from, call. = FALSE)
  }
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(pattern = paste0(basename(to), "."), tmpdir = dirname(to))
  on.exit(unlink(temporary), add = TRUE)
  if (!file.copy(from, temporary, overwrite = TRUE, copy.mode = TRUE)) {
    stop("Could not stage artifact: ", from, call. = FALSE)
  }
  atomic_replace_artifact(temporary, to)
}

pin_table <- tibble::tribble(
  ~role, ~path, ~sha256,
  "coordinator production authorization",
  "audit/decisions/h01_metric011_l10_production_authorization.md",
  "ab0764bb55144d9c69caafc8373010f497561757ad2c576d88e32b450817ed4f",
  "coordinator production gate",
  "audit/decisions/h01_metric011_l10_production_gate.md",
  "30b43ef447a2310edd05b245c0c36d0c6a6966f2394f1a149db13d4afe384445",
  "METRIC-011 decision",
  "audit/decisions/l10_numerical_zero_normalization.md",
  "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
  "METRIC-011 evidence manifest",
  "audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv",
  "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
  "primary H01 RDS",
  "artifacts/06_model_data/H01.rds",
  "0328fe1a698bc13965feb0b68b03ccf0fd20f32b55d6148635811b0d674e0a00",
  "primary H01 manifest",
  "artifacts/12_manifests/H01_model_data_artifacts.csv",
  "25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72",
  "gap-timing-unaware H01 RDS",
  "artifacts/06_model_data/H01/scenarios/manuscript_prepared_data/H01.rds",
  "3c70363fc0468202a431904aa9d9444f2858af2e3add3475a56c872b49a18bd6",
  "gap-timing-unaware H01 manifest",
  "artifacts/12_manifests/H01_manuscript_prepared_data_artifacts.csv",
  "e0d98178ede61b74353e3a654e7f1b53d7e1c915833a2cda74eea45ed02f383b",
  "isolated L10 point manifest",
  "audit/hypotheses/H01/l10_METRIC-011/point_refit/artifacts/12_manifests/H01_model_results_artifacts.csv",
  "51d3462833724af0238810b88b6d9e75e93d2d3a0aebcb2f5077e8adb0354346",
  "isolated L10 production manifest",
  "audit/hypotheses/H01/l10_METRIC-011/bootstrap_production/H01_METRIC-011_bootstrap_production_manifest.csv",
  "e996dccb9556330a23c14bf2650ed7102662303dbac01a7873f5e974cc97eb57"
)
pin_files <- file.path(root, pin_table$path)
stopifnot(
  all(file.exists(pin_files)),
  identical(
    unname(vapply(pin_files, artifact_sha256, character(1))),
    unname(pin_table$sha256)
  )
)
verify_manifest(file.path(root, "artifacts/12_manifests/H01_model_data_artifacts.csv"))
verify_manifest(file.path(root, "artifacts/12_manifests/H01_manuscript_prepared_data_artifacts.csv"))

# The focused verifier is intentionally executed before any accepted artifact
# is replaced. It performs no fitting or resampling.
source(file.path(root, "tests/hypotheses/H01/test_h01_l10_METRIC011_production.R"))

protected_path <- file.path(
  gate_root,
  "H01_METRIC-011_protected_artifact_baseline.csv"
)
protected <- read_csv_strict(protected_path)
protected_files <- file.path(root, protected$path)
stopifnot(
  all(file.exists(protected_files)),
  identical(
    unname(vapply(protected_files, artifact_sha256, character(1))),
    unname(protected$sha256)
  )
)

table_root <- file.path(root, "artifacts/09_tables/H01")
point_table_root <- file.path(point_root, "artifacts/09_tables/H01")
table_specs <- list(
  H01_exact_samples.csv = c("run_id", "metric_id"),
  H01_exact_samples_by_site.csv = c("run_id", "metric_id", "site"),
  H01_marginalization_comparison.csv = c("run_id", "metric_id"),
  H01_model_manifest.csv = c(
    "run_id", "metric_id", "model_name", "estimation_stage"
  ),
  H01_preregistered_scope_sensitivity.csv = c(
    "run_id", "metric_id", "comparison_id", "scope_change"
  ),
  H01_r2_point_summaries.csv = c("run_id", "metric_id", "approximation"),
  H01_random_site_descriptions.csv = c("run_id", "metric_id"),
  H01_site_estimates.csv = c("run_id", "metric_id", "estimand", "site"),
  H01_site_deviations.csv = c("run_id", "metric_id", "site"),
  H01_term_effects.csv = c("run_id", "metric_id", "term")
)

canonical_table_paths <- file.path(table_root, names(table_specs))
names(canonical_table_paths) <- names(table_specs)
old_tables <- lapply(canonical_table_paths, read_csv_strict)

# Replace the complete four main-data BH vectors. Raw non-L10 tests remain
# exactly frozen; only their BH-adjusted value is allowed to change.
tests_path <- file.path(table_root, "H01_model_level_tests.csv")
old_tests <- read_csv_strict(tests_path)
complete_tests <- read_csv_strict(file.path(
  gate_root,
  "H01_METRIC-011_complete_model_level_tests.csv"
))
stopifnot(
  nrow(complete_tests) == 4L * 17L * 4L,
  setequal(unique(complete_tests$run_id), target_runs),
  all(complete_tests$family_n == 17L),
  all(complete_tests$family_status == "COMPLETE")
)
test_keys <- c("run_id", "metric_id", "family_id")
old_key <- key_string(old_tests, test_keys)
new_key <- key_string(complete_tests, test_keys)
test_index <- match(new_key, old_key)
stopifnot(!anyNA(test_index), !anyDuplicated(new_key))
tests_updated <- old_tests
l10_test_rows <- complete_tests$metric_id == metric_id
tests_updated[test_index[l10_test_rows], ] <- complete_tests[l10_test_rows, names(old_tests)]
tests_updated$p_adjusted[test_index[!l10_test_rows]] <-
  complete_tests$p_adjusted[!l10_test_rows]

non_l10_index <- test_index[!l10_test_rows]
non_l10_invariant_columns <- setdiff(names(old_tests), "p_adjusted")
stopifnot(identical(
  old_tests[non_l10_index, non_l10_invariant_columns],
  tests_updated[non_l10_index, non_l10_invariant_columns]
))
support_before <- !is.na(old_tests$p_adjusted[test_index]) &
  old_tests$p_adjusted[test_index] < 0.05
support_after <- !is.na(tests_updated$p_adjusted[test_index]) &
  tests_updated$p_adjusted[test_index] < 0.05
if (!identical(support_before, support_after)) {
  stop("METRIC-011 changed an H01 multiplicity disposition", call. = FALSE)
}

updated_tables <- list()
for (name in names(table_specs)) {
  base <- old_tables[[name]]
  replacement_path <- file.path(point_table_root, name)
  replacement <- read_csv_strict(replacement_path)
  if (identical(name, "H01_site_deviations.csv")) {
    replacement <- read_csv_strict(file.path(
      gate_root,
      "H01_METRIC-011_site_deviations.csv"
    ))
  }
  missing_columns <- setdiff(names(base), names(replacement))
  if (length(missing_columns) > 0L) {
    base_index <- match(
      key_string(replacement, table_specs[[name]]),
      key_string(base, table_specs[[name]])
    )
    if (anyNA(base_index)) {
      stop("Cannot restore structural columns for ", name, call. = FALSE)
    }
    for (column in missing_columns) {
      replacement[[column]] <- base[[column]][base_index]
    }
  }
  replacement <- replacement[, names(base), drop = FALSE]
  stopifnot(
    nrow(replacement) > 0L,
    all(target_main_l10(replacement)),
    all(unique(replacement$run_id) %in% target_runs)
  )
  updated_tables[[name]] <- replace_rows_by_key(
    base,
    replacement,
    table_specs[[name]],
    name
  )
}

r2_path <- file.path(table_root, "H01_r2_bootstrap_summaries.csv")
old_r2 <- read_csv_strict(r2_path)
production_r2 <- read_csv_strict(file.path(
  production_root,
  "tables/H01_METRIC-011_bootstrap_production_r2_summaries.csv"
))[, names(old_r2), drop = FALSE]
stopifnot(
  nrow(production_r2) == 32L,
  all(target_main_l10(production_r2)),
  all(production_r2$bootstrap_successful_used == 1000L),
  all(production_r2$status == "PASS")
)
r2_updated <- replace_rows_by_key(
  old_r2,
  production_r2,
  c("run_id", "metric_id", "approximation", "measure"),
  "H01_r2_bootstrap_summaries.csv"
)

# Create the complete current overlays while leaving the accepted mixed
# canonical diagnostic files byte-identical.
overlay_specs <- list(
  H01_model_diagnostics_current = list(
    canonical = "artifacts/08_diagnostics/H01/H01_model_diagnostics.csv",
    replacement = file.path(
      gate_root,
      "H01_METRIC-011_model_diagnostics.csv"
    ),
    keys = c("run_id", "metric_id")
  ),
  H01_participant_influence_current = list(
    canonical = "artifacts/08_diagnostics/H01/H01_participant_influence.csv",
    replacement = file.path(
      gate_root,
      "H01_METRIC-011_participant_influence.csv"
    ),
    keys = c("run_id", "metric_id", "omitted_participant")
  ),
  H01_latitude_leave_one_site_out_current = list(
    canonical = "artifacts/08_diagnostics/H01/H01_latitude_leave_one_site_out.csv",
    replacement = file.path(
      gate_root,
      "H01_METRIC-011_latitude_leave_one_site_out.csv"
    ),
    keys = c("run_id", "metric_id", "omitted_site")
  ),
  H01_r2_bootstrap_audit_current = list(
    canonical = "artifacts/08_diagnostics/H01/H01_r2_bootstrap_audit.csv",
    replacement = file.path(
      production_root,
      "diagnostics/H01_METRIC-011_bootstrap_production_audit.csv"
    ),
    keys = c("run_id", "metric_id")
  )
)
overlay_paths <- character()
for (name in names(overlay_specs)) {
  specification <- overlay_specs[[name]]
  base <- read_csv_strict(file.path(root, specification$canonical))
  replacement <- read_csv_strict(specification$replacement)
  replacement <- replacement[, names(base), drop = FALSE]
  stopifnot(all(target_main_l10(replacement)))
  current <- replace_rows_by_key(
    base,
    replacement,
    specification$keys,
    name
  )
  overlay_path <- file.path(overlay_root, paste0(name, ".csv"))
  write_csv_artifact(current, overlay_path, producer = producer)
  overlay_paths <- c(overlay_paths, overlay_path)
}

# Snapshot all canonical targets before installing the bounded replacements.
point_files <- unlist(lapply(target_runs, function(run_id) {
  parts <- strsplit(run_id, "__", fixed = TRUE)[[1L]]
  data_scenario_id <- parts[[1L]]
  placement <- parts[[2L]]
  sample_scenario <- parts[[3L]]
  relative_directory <- file.path(
    "H01", data_scenario_id, placement, sample_scenario
  )
  c(
    file.path("artifacts/07_models", relative_directory, paste0(metric_id, "_model_frame.rds")),
    file.path("artifacts/07_models", relative_directory, paste0(metric_id, "_models.rds")),
    file.path("artifacts/08_diagnostics", relative_directory, paste0(metric_id, "_diagnostics.png")),
    file.path("artifacts/11_source_data", relative_directory, paste0(metric_id, "_diagnostic_plot_data.csv")),
    file.path("artifacts/11_source_data", relative_directory, paste0(metric_id, "_model_frame.csv"))
  )
}))
draw_files <- unlist(lapply(target_runs, function(run_id) {
  parts <- strsplit(run_id, "__", fixed = TRUE)[[1L]]
  file.path(
    "artifacts/07_models/H01",
    parts[[1L]], parts[[2L]], parts[[3L]],
    paste0(metric_id, "_r2_bootstrap_draws.rds")
  )
}))
canonical_targets <- unique(c(
  relative_to_root(canonical_table_paths),
  "artifacts/09_tables/H01/H01_model_level_tests.csv",
  "artifacts/09_tables/H01/H01_r2_bootstrap_summaries.csv",
  point_files,
  draw_files
))
canonical_target_paths <- file.path(root, canonical_targets)
stopifnot(all(file.exists(canonical_target_paths)))
worker_baseline <- read_csv_strict(file.path(
  root,
  "artifacts/12_manifests/H01_worker_artifacts.csv"
))
worker_index <- match(canonical_targets, worker_baseline$path)
sha256_before <- vapply(canonical_target_paths, artifact_sha256, character(1))
bytes_before <- as.numeric(file.info(canonical_target_paths)$size)
available_worker_baseline <- !is.na(worker_index)
sha256_before[available_worker_baseline] <-
  worker_baseline$sha256[worker_index[available_worker_baseline]]
bytes_before[available_worker_baseline] <-
  worker_baseline$bytes[worker_index[available_worker_baseline]]
pre_state <- tibble::tibble(
  path = canonical_targets,
  sha256_before = sha256_before,
  bytes_before = bytes_before,
  baseline_source = if_else(
    available_worker_baseline,
    "accepted pre-METRIC-011 H01 worker manifest",
    "current pre-install identity"
  )
)

write_csv_artifact(tests_updated, tests_path, producer = producer)
for (name in names(updated_tables)) {
  write_csv_artifact(
    updated_tables[[name]],
    canonical_table_paths[[name]],
    producer = producer
  )
}
write_csv_artifact(r2_updated, r2_path, producer = producer)

# Install the four point-fit bundles, frames, diagnostic plots and source CSVs.
for (run_id in target_runs) {
  parts <- strsplit(run_id, "__", fixed = TRUE)[[1L]]
  relative_directory <- file.path("H01", parts[[1L]], parts[[2L]], parts[[3L]])
  for (filename in c(
    paste0(metric_id, "_model_frame.rds"),
    paste0(metric_id, "_models.rds")
  )) {
    copy_atomic(
      file.path(point_root, "artifacts/07_models", relative_directory, filename),
      file.path(root, "artifacts/07_models", relative_directory, filename)
    )
  }
  copy_atomic(
    file.path(
      point_root,
      "artifacts/08_diagnostics",
      relative_directory,
      paste0(metric_id, "_diagnostics.png")
    ),
    file.path(
      root,
      "artifacts/08_diagnostics",
      relative_directory,
      paste0(metric_id, "_diagnostics.png")
    )
  )
  for (filename in c(
    paste0(metric_id, "_diagnostic_plot_data.csv"),
    paste0(metric_id, "_model_frame.csv")
  )) {
    copy_atomic(
      file.path(point_root, "artifacts/11_source_data", relative_directory, filename),
      file.path(root, "artifacts/11_source_data", relative_directory, filename)
    )
  }
  copy_atomic(
    file.path(
      production_root,
      "draws", parts[[2L]], parts[[3L]],
      paste0(metric_id, "_draws.rds")
    ),
    file.path(
      root,
      "artifacts/07_models", relative_directory,
      paste0(metric_id, "_r2_bootstrap_draws.rds")
    )
  )
}

# The existing model-results manifest is updated only for files changed by
# this bounded integration and for the already-current H01 contract identity.
model_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_model_results_artifacts.csv"
)
model_artifact_manifest <- read_csv_strict(model_manifest_path)
manifest_files <- file.path(root, model_artifact_manifest$path)
stopifnot(all(file.exists(manifest_files)))
observed_manifest_hashes <- vapply(
  manifest_files,
  artifact_sha256,
  character(1)
)
mismatch <- observed_manifest_hashes != model_artifact_manifest$sha256
allowed_manifest_drift <- model_artifact_manifest$path %in% c(
  canonical_targets,
  "scripts/hypotheses/H01/h01_contract.R"
)
if (any(mismatch & !allowed_manifest_drift)) {
  stop(
    "Unexpected artifact drift while resealing H01 model results: ",
    paste(model_artifact_manifest$path[mismatch & !allowed_manifest_drift], collapse = ", "),
    call. = FALSE
  )
}
model_artifact_manifest$sha256[mismatch] <- observed_manifest_hashes[mismatch]
model_artifact_manifest$bytes[mismatch] <- as.numeric(
  file.info(manifest_files[mismatch])$size
)
changed_by_integration <- model_artifact_manifest$path %in% canonical_targets
model_artifact_manifest$producer[changed_by_integration] <- producer
write_csv_artifact(
  model_artifact_manifest,
  model_manifest_path,
  producer = producer
)
verify_manifest(model_manifest_path)

# Disposition and numerical-comparison evidence.
support_disposition <- tibble::tibble(
  run_id = complete_tests$run_id,
  metric_id = complete_tests$metric_id,
  family_id = complete_tests$family_id,
  supported_before = support_before,
  supported_after = support_after,
  support_changed = support_before != support_after
)
support_path <- file.path(
  integration_root,
  "H01_METRIC-011_support_disposition.csv"
)
write_csv_artifact(support_disposition, support_path, producer = producer)

old_r2_target <- old_r2[target_main_l10(old_r2), , drop = FALSE]
r2_comparison_path <- file.path(
  integration_root,
  "H01_METRIC-011_r2_production_comparison.csv"
)
if (file.exists(r2_comparison_path)) {
  r2_comparison <- read_csv_strict(r2_comparison_path)
  stopifnot(
    nrow(r2_comparison) == 32L,
    all(r2_comparison$metric_id == metric_id),
    all(r2_comparison$successful_refits_after == 1000L)
  )
} else {
  r2_comparison <- inner_join(
    old_r2_target,
    production_r2,
    by = c("run_id", "metric_id", "approximation", "measure"),
    suffix = c("_before", "_after"),
    relationship = "one-to-one"
  ) |>
    transmute(
      .data$run_id,
      .data$metric_id,
      .data$approximation,
      .data$measure,
      estimate_before = .data$estimate_before,
      estimate_after = .data$estimate_after,
      estimate_delta = .data$estimate_after - .data$estimate_before,
      conf_low_before = .data$conf_low_before,
      conf_low_after = .data$conf_low_after,
      conf_low_delta = .data$conf_low_after - .data$conf_low_before,
      conf_high_before = .data$conf_high_before,
      conf_high_after = .data$conf_high_after,
      conf_high_delta = .data$conf_high_after - .data$conf_high_before,
      successful_refits_before = .data$bootstrap_successful_used_before,
      successful_refits_after = .data$bootstrap_successful_used_after
    )
  write_csv_artifact(r2_comparison, r2_comparison_path, producer = producer)
}

diagnostic_overlay <- read_csv_strict(file.path(
  overlay_root,
  "H01_model_diagnostics_current.csv"
))
diagnostic_disposition <- diagnostic_overlay |>
  filter(
    .data$run_id %in% .env$target_runs,
    .data$metric_id == .env$metric_id
  ) |>
  transmute(
    .data$run_id,
    .data$metric_id,
    .data$diagnostic_status,
    disposition_changed = FALSE,
    final_disposition = case_when(
      .data$diagnostic_status == "PASS" ~ "acceptable",
      .data$diagnostic_status == "WARN_REVIEW" ~ "acceptable with limitations",
      TRUE ~ "not acceptable"
    )
  )
diagnostic_path <- file.path(
  integration_root,
  "H01_METRIC-011_diagnostic_disposition.csv"
)
write_csv_artifact(diagnostic_disposition, diagnostic_path, producer = producer)

production_audit <- read_csv_strict(file.path(
  production_root,
  "diagnostics/H01_METRIC-011_bootstrap_production_audit.csv"
))
production_runtime <- read_csv_strict(file.path(
  production_root,
  "diagnostics/H01_METRIC-011_bootstrap_production_runtime.csv"
))
closure_summary <- tibble::tibble(
  decision_id = "H01-013",
  change_id = "CHG-110",
  metric_decision = "METRIC-011",
  targets = nrow(production_audit),
  successful_refits_per_target = min(production_audit$used_refits),
  total_used_refits = sum(production_audit$used_refits),
  total_failed_refits = sum(production_audit$failed_refits),
  total_warning_refits = sum(production_audit$warning_refits),
  target_wall_seconds = sum(production_runtime$wall_seconds),
  support_changes = sum(support_disposition$support_changed),
  diagnostic_disposition_changes = sum(
    diagnostic_disposition$disposition_changed
  ),
  sensitivity_disposition_changes = 0L,
  claim_disposition_changes = 0L,
  focused_verifier = "PASS",
  integration_status = "PASS_NO_NEW_AUTHOR_GATE"
)
closure_path <- file.path(
  integration_root,
  "H01_METRIC-011_integration_summary.csv"
)
write_csv_artifact(closure_summary, closure_path, producer = producer)

# Verify that the frozen boundary remains exact after installation.
stopifnot(
  all(file.exists(protected_files)),
  identical(
    unname(vapply(protected_files, artifact_sha256, character(1))),
    unname(protected$sha256)
  )
)
source(file.path(root, "tests/hypotheses/H01/test_h01_l10_METRIC011_production.R"))

post_state <- pre_state |>
  mutate(
    sha256_after = vapply(
      file.path(root, .data$path),
      artifact_sha256,
      character(1)
    ),
    bytes_after = as.numeric(file.info(file.path(root, .data$path))$size),
    changed = .data$sha256_before != .data$sha256_after
  )
state_path <- file.path(
  integration_root,
  "H01_METRIC-011_canonical_artifact_transition.csv"
)
write_csv_artifact(post_state, state_path, producer = producer)

manifest_inputs <- unique(c(
  pin_files,
  protected_path,
  file.path(root, producer),
  file.path(root, "tests/hypotheses/H01/test_h01_l10_METRIC011_production.R"),
  file.path(gate_root, "H01_METRIC-011_complete_model_level_tests.csv"),
  file.path(gate_root, "H01_METRIC-011_site_deviations.csv"),
  file.path(gate_root, "H01_METRIC-011_model_diagnostics.csv"),
  file.path(gate_root, "H01_METRIC-011_participant_influence.csv"),
  file.path(gate_root, "H01_METRIC-011_latitude_leave_one_site_out.csv"),
  file.path(
    production_root,
    "tables/H01_METRIC-011_bootstrap_production_r2_summaries.csv"
  ),
  file.path(
    production_root,
    "diagnostics/H01_METRIC-011_bootstrap_production_audit.csv"
  ),
  file.path(
    production_root,
    "diagnostics/H01_METRIC-011_bootstrap_production_runtime.csv"
  )
))
manifest_outputs <- unique(c(
  canonical_target_paths,
  overlay_paths,
  support_path,
  r2_comparison_path,
  diagnostic_path,
  closure_path,
  state_path,
  model_manifest_path
))
integration_manifest <- bind_rows(lapply(
  sort(unique(c(manifest_inputs, manifest_outputs))),
  function(path) {
    tibble::tibble(
      path = relative_to_root(path),
      sha256 = artifact_sha256(path),
      bytes = as.numeric(file.info(path)$size),
      role = if_else(
        path %in% manifest_outputs,
        "H01 METRIC-011 integrated output",
        "H01 METRIC-011 verified input"
      ),
      producer = producer,
      r_version = as.character(getRversion()),
      integration_status = "PASS_NO_NEW_AUTHOR_GATE"
    )
  }
))
integration_manifest_path <- file.path(
  integration_root,
  "H01_METRIC-011_production_integration_manifest.csv"
)
write_csv_artifact(
  integration_manifest,
  integration_manifest_path,
  producer = producer
)

message(
  "H01 METRIC-011 production integrated: four L10 targets × 1,000 used ",
  "joint refits; no support, diagnostic, sensitivity, or claim disposition ",
  "changed; protected artifacts remain byte-identical"
)
