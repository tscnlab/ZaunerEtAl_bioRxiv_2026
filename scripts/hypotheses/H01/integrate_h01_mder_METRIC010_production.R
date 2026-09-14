# Integrate the author-approved H01 METRIC-010 MDER production results.
#
# This is a bounded, no-refit integration. It replaces only metric-order 17
# point-model artifacts and rows, promotes the eight stored 1,000-refit MDER
# bootstrap outputs, and recomputes the complete affected 17-test FDR vectors
# from already accepted raw p-values. No model is fitted or resampled here.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/multiplicity.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H01 METRIC-010 integration requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(vctrs)
})

approval <- Sys.getenv("H01_MDER_INTEGRATION_APPROVAL", unset = "")
if (!identical(approval, "approved_2026-08-31")) {
  stop("Missing exact H01 METRIC-010 integration approval token", call. = FALSE)
}

producer <- paste0(
  "scripts/hypotheses/H01/",
  "integrate_h01_mder_METRIC010_production.R"
)
old_metric_id <- "mder_ratio_of_integrals"
metric_id <- "mder_mean_of_viable_ratios"
target_runs <- c(
  "main__chest__all_available",
  "main__chest__paired_common_sample",
  "main__glasses__all_available",
  "main__glasses__paired_common_sample",
  "manuscript_prepared_data__chest__all_available",
  "manuscript_prepared_data__chest__paired_common_sample",
  "manuscript_prepared_data__glasses__all_available",
  "manuscript_prepared_data__glasses__paired_common_sample"
)
run_order <- h01_run_registry()$run_id

audit_root <- file.path(root, "audit/hypotheses/H01/mder_METRIC-010")
point_root <- file.path(audit_root, "point_refit_repaired_gap")
production_root <- file.path(audit_root, "bootstrap_production")
integration_root <- file.path(audit_root, "production_integration")
candidate_root <- file.path(integration_root, "candidate")
dir.create(candidate_root, recursive = TRUE, showWarnings = FALSE)

relative_to_root <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(root, "/")
  ifelse(
    startsWith(normalized, prefix),
    substring(normalized, nchar(prefix) + 1L),
    normalized
  )
}

read_csv_strict <- function(path) {
  if (!file.exists(path)) {
    stop("Missing H01 METRIC-010 integration input: ", path, call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

hash_pin <- function(path, expected) {
  if (!file.exists(path)) {
    stop("Missing pinned input: ", path, call. = FALSE)
  }
  observed <- artifact_sha256(path)
  if (!identical(observed, expected)) {
    stop(
      "Pinned input drift: ", relative_to_root(path),
      " expected ", expected, " observed ", observed,
      call. = FALSE
    )
  }
  invisible(path)
}

pin_table <- tibble::tribble(
  ~role, ~path, ~sha256,
  "author production authorization",
  "audit/hypotheses/H01/mder_METRIC-010/H01_METRIC-010_production_authorization.md",
  "f9279a46c73b5feede48adaeee98306a4841183468688446ce91cf09045e33af",
  "METRIC-010 decision",
  "audit/decisions/mder_mean_of_viable_ratios.md",
  "1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de",
  "accepted point gate",
  "audit/hypotheses/H01/mder_METRIC-010/H01_METRIC-010_author_gate.md",
  "c4d9842dc59b51afcc7fc50426903ab9b656fc29beac9e9cba2dcf4372f142cc",
  "isolated point manifest",
  paste0(
    "audit/hypotheses/H01/mder_METRIC-010/point_refit_repaired_gap/",
    "artifacts/12_manifests/H01_model_results_artifacts.csv"
  ),
  "f9e8d2414b1242d3d71510837c9c086791bfd72292b5af615131291e491bd41e",
  "production manifest",
  paste0(
    "audit/hypotheses/H01/mder_METRIC-010/bootstrap_production/",
    "H01_METRIC-010_bootstrap_production_manifest.csv"
  ),
  "9ba121a1847e5a5b649b691e578a5e416edc34be16d87f2ed178f380d0ffdf56",
  "focused production verifier",
  "tests/hypotheses/H01/test_h01_mder_METRIC010_production.R",
  "22e3f66302f9194b22a1fbe32ab44c339478e9dcadd5fe335fa5d5201344bbef"
)
invisible(mapply(
  function(path, sha256) hash_pin(file.path(root, path), sha256),
  pin_table$path,
  pin_table$sha256,
  SIMPLIFY = FALSE
))

# The production verifier checks current-input bridging, exact target counts,
# production intervals, failure accounting, and the non-circular production
# manifest before any canonical artifact is prepared for replacement.
source(file.path(root, "tests/hypotheses/H01/test_h01_mder_METRIC010_production.R"))

key_string <- function(data, keys) {
  stopifnot(all(keys %in% names(data)))
  values <- lapply(data[keys], function(value) {
    value <- as.character(value)
    value[is.na(value)] <- "<NA>"
    value
  })
  do.call(paste, c(values, sep = "\r"))
}

cast_like <- function(replacement, template, label) {
  missing <- setdiff(names(template), names(replacement))
  extra <- setdiff(names(replacement), names(template))
  if (length(missing) > 0L || length(extra) > 0L) {
    stop(
      "Column mismatch in ", label, ": missing=",
      paste(missing, collapse = ","), "; extra=",
      paste(extra, collapse = ","),
      call. = FALSE
    )
  }
  replacement <- replacement[, names(template), drop = FALSE]
  for (column in names(template)) {
    replacement[[column]] <- vctrs::vec_cast(
      replacement[[column]],
      template[[column]],
      x_arg = paste0(label, "$", column),
      to_arg = paste0("canonical$", column)
    )
  }
  replacement
}

replace_metric_rows <- function(base, replacement, keys, label) {
  old_index <- which(
    base$metric_order == 17L & base$metric_id == old_metric_id
  )
  if (length(old_index) != nrow(replacement) || length(old_index) == 0L) {
    stop(
      "Unexpected metric-order 17 row count in ", label,
      ": canonical=", length(old_index),
      ", replacement=", nrow(replacement),
      call. = FALSE
    )
  }
  replacement <- cast_like(replacement, base, label)
  old_key <- key_string(base[old_index, , drop = FALSE], keys)
  new_key <- key_string(replacement, keys)
  if (anyDuplicated(old_key) || anyDuplicated(new_key)) {
    stop("Duplicate replacement key in ", label, call. = FALSE)
  }
  destination <- old_index[match(new_key, old_key)]
  if (anyNA(destination)) {
    stop("Replacement key absent from canonical ", label, call. = FALSE)
  }
  for (column in names(base)) {
    base[[column]][destination] <- replacement[[column]]
  }
  base
}

replace_metric_block <- function(base, replacement, keys, label) {
  old_index <- which(
    base$metric_order == 17L & base$metric_id == old_metric_id
  )
  if (length(old_index) == 0L) {
    stop("Missing superseded metric-order 17 rows in ", label, call. = FALSE)
  }
  replacement <- cast_like(replacement, base, label)
  replacement_key <- key_string(replacement, keys)
  if (anyDuplicated(replacement_key)) {
    stop("Duplicate replacement key in ", label, call. = FALSE)
  }
  retained <- base[-old_index, , drop = FALSE]
  retained$.source_order <- seq_len(nrow(retained))
  replacement$.source_order <- nrow(retained) + seq_len(nrow(replacement))
  bind_rows(retained, replacement) |>
    mutate(.run_order = match(.data$run_id, run_order)) |>
    arrange(.data$.run_order, .data$metric_order, .data$.source_order) |>
    select(-".run_order", -".source_order")
}

canonical_table_root <- file.path(root, "artifacts/09_tables/H01")
point_table_root <- file.path(point_root, "artifacts/09_tables/H01")
canonical_diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H01")
point_diagnostic_root <- file.path(point_root, "artifacts/08_diagnostics/H01")

table_specs <- list(
  H01_exact_samples.csv = c("run_id"),
  H01_exact_samples_by_site.csv = c("run_id", "site"),
  H01_marginalization_comparison.csv = c("run_id"),
  H01_model_manifest.csv = c("run_id", "model_name", "estimation_stage"),
  H01_r2_point_summaries.csv = c("run_id", "approximation"),
  H01_random_site_descriptions.csv = c("run_id"),
  H01_site_estimates.csv = c("run_id", "estimand", "site"),
  H01_site_deviations.csv = c("run_id", "site"),
  H01_term_effects.csv = c("run_id", "term")
)

merged <- list()
for (name in names(table_specs)) {
  base <- read_csv_strict(file.path(canonical_table_root, name))
  replacement <- read_csv_strict(file.path(point_table_root, name))
  stopifnot(
    nrow(replacement) > 0L,
    all(replacement$metric_id == metric_id),
    setequal(unique(replacement$run_id), target_runs)
  )
  merged[[name]] <- replace_metric_rows(
    base,
    replacement,
    table_specs[[name]],
    name
  )
}

# Replace raw MDER tests, then recompute every affected complete family using
# the current accepted raw p-values, including the accepted METRIC-011 values.
tests_name <- "H01_model_level_tests.csv"
tests_base <- read_csv_strict(file.path(canonical_table_root, tests_name))
tests_point <- read_csv_strict(file.path(point_table_root, tests_name))
derived_test_columns <- c(
  "family_instance_id", "p_adjusted", "family_rank",
  "family_observed_tests", "family_status"
)
tests_raw <- bind_rows(
  tests_base |>
    filter(!(.data$metric_order == 17L & .data$metric_id == old_metric_id)) |>
    select(-any_of(derived_test_columns)),
  tests_point |>
    select(-any_of(derived_test_columns))
) |>
  mutate(family_instance_id = paste(.data$run_id, .data$family_id, sep = "::"))
tests_merged <- adjust_result_families(
  tests_raw,
  family_col = "family_instance_id",
  p_col = "p_raw",
  family_n_col = "family_n",
  output_col = "p_adjusted",
  method = "BH"
) |>
  group_by(.data$family_instance_id) |>
  mutate(
    family_rank = ifelse(
      is.na(.data$p_raw),
      NA_integer_,
      rank(.data$p_raw, ties.method = "min", na.last = "keep")
    ),
    family_observed_tests = sum(!is.na(.data$p_raw)),
    family_status = "COMPLETE"
  ) |>
  ungroup() |>
  arrange(match(.data$run_id, run_order), .data$metric_order, .data$family_order)
tests_merged <- cast_like(tests_merged, tests_base, tests_name)
stopifnot(
  nrow(tests_merged) == 8L * 17L * 4L,
  all(tests_merged$family_n == 17L),
  all(tests_merged$family_observed_tests %in% c(15L, 17L)),
  all(tests_merged$family_status == "COMPLETE")
)
merged[[tests_name]] <- tests_merged

# Reattach the new complete-family overall-site p-value to every contrast.
site_name <- "H01_site_deviations.csv"
site_merged <- merged[[site_name]] |>
  select(-any_of(c(
    "overall_site_p_adjusted", "inferential_followup_supported"
  ))) |>
  left_join(
    tests_merged |>
      filter(.data$family_id == "H01-F1-site") |>
      select(
        "run_id", "metric_id",
        overall_site_p_adjusted = "p_adjusted"
      ),
    by = c("run_id", "metric_id"),
    relationship = "many-to-one"
  ) |>
  mutate(
    inferential_followup_supported =
      !is.na(.data$overall_site_p_adjusted) &
      .data$overall_site_p_adjusted < 0.05
  )
merged[[site_name]] <- cast_like(
  site_merged,
  read_csv_strict(file.path(canonical_table_root, site_name)),
  site_name
)

# Recompute the registered-scope FDR families after replacing MDER.
scope_name <- "H01_preregistered_scope_sensitivity.csv"
scope_base <- read_csv_strict(file.path(canonical_table_root, scope_name))
scope_point <- read_csv_strict(file.path(point_table_root, scope_name))
scope_derived <- c(
  "family_order", "family_id", "family_label", "adjustment_method",
  "family_n", "family_instance_id", "p_adjusted", "family_status"
)
scope_raw <- bind_rows(
  scope_base |>
    filter(!(.data$metric_order == 17L & .data$metric_id == old_metric_id)) |>
    select(-any_of(scope_derived)),
  scope_point |>
    select(-any_of(scope_derived))
) |>
  mutate(
    family_id = case_when(
      .data$comparison_id == "site_full_vs_no_site" ~
        "H01-S1-registered-site",
      .data$comparison_id == "latitude_full_vs_no_latitude" ~
        "H01-S2-registered-latitude",
      .data$comparison_id == "site_full_vs_latitude_full" ~
        "H01-S3-registered-adequacy",
      .data$comparison_id == "site_full_vs_no_photoperiod" ~
        "H01-S4-registered-photoperiod",
      TRUE ~ NA_character_
    ),
    family_n = ifelse(
      .data$family_id == "H01-S4-registered-photoperiod", 5L, 17L
    ),
    family_instance_id = paste(.data$run_id, .data$family_id, sep = "::")
  ) |>
  filter(!is.na(.data$family_id))
scope_merged <- adjust_result_families(
  scope_raw,
  family_col = "family_instance_id",
  p_col = "p_raw",
  family_n_col = "family_n",
  output_col = "p_adjusted",
  method = "BH"
) |>
  mutate(family_status = "COMPLETE") |>
  left_join(
    scope_base |>
      select(
        "run_id", "metric_order", "comparison_id",
        "family_order", "family_label", "adjustment_method"
      ),
    by = c("run_id", "metric_order", "comparison_id"),
    relationship = "many-to-one"
  ) |>
  arrange(match(.data$run_id, run_order), .data$metric_order, .data$family_id)
merged[[scope_name]] <- cast_like(scope_merged, scope_base, scope_name)

diagnostic_specs <- list(
  H01_model_diagnostics.csv = c("run_id"),
  H01_participant_influence.csv = c("run_id", "omitted_participant"),
  H01_latitude_leave_one_site_out.csv = c("run_id", "omitted_site")
)
for (name in names(diagnostic_specs)) {
  base <- read_csv_strict(file.path(canonical_diagnostic_root, name))
  replacement <- read_csv_strict(file.path(point_diagnostic_root, name))
  merged[[name]] <- if (identical(name, "H01_participant_influence.csv")) {
    replace_metric_block(
      base,
      replacement,
      diagnostic_specs[[name]],
      name
    )
  } else {
    replace_metric_rows(
      base,
      replacement,
      diagnostic_specs[[name]],
      name
    )
  }
}

r2_name <- "H01_r2_bootstrap_summaries.csv"
r2_base <- read_csv_strict(file.path(canonical_table_root, r2_name))
r2_production <- read_csv_strict(file.path(
  production_root,
  "tables/H01_METRIC-010_bootstrap_production_r2_summaries.csv"
)) |>
  select(all_of(names(r2_base)))
stopifnot(
  nrow(r2_production) == 64L,
  setequal(unique(r2_production$run_id), target_runs),
  all(r2_production$metric_id == metric_id),
  all(r2_production$bootstrap_successful_used == 1000L),
  all(r2_production$status == "PASS")
)
merged[[r2_name]] <- replace_metric_rows(
  r2_base,
  r2_production,
  c("run_id", "approximation", "measure"),
  r2_name
)

bootstrap_name <- "H01_r2_bootstrap_audit.csv"
bootstrap_base <- read_csv_strict(file.path(
  canonical_diagnostic_root,
  bootstrap_name
))
bootstrap_production <- read_csv_strict(file.path(
  production_root,
  "diagnostics/H01_METRIC-010_bootstrap_production_audit.csv"
)) |>
  select(all_of(names(bootstrap_base)))
merged[[bootstrap_name]] <- replace_metric_rows(
  bootstrap_base,
  bootstrap_production,
  c("run_id"),
  bootstrap_name
)
stopifnot(
  all(bootstrap_production$used_refits == 1000L),
  all(bootstrap_production$status == "PASS")
)

failure_name <- "H01_r2_bootstrap_failures.csv"
failure_base <- read_csv_strict(file.path(
  canonical_diagnostic_root,
  failure_name
))
failure_production <- read_csv_strict(file.path(
  production_root,
  "diagnostics/H01_METRIC-010_bootstrap_production_failures.csv"
)) |>
  select(all_of(names(failure_base)))
merged[[failure_name]] <- replace_metric_block(
  failure_base,
  failure_production,
  c("run_id", "attempt"),
  failure_name
)
stopifnot(
  nrow(failure_production) == 2L,
  all(failure_production$metric_id == metric_id)
)

# Confirm that production point values exactly reproduce the accepted point
# gate and that the current METRIC-011 raw-p update changes no accepted gate
# support disposition.
point_r2 <- read_csv_strict(file.path(
  point_table_root,
  "H01_r2_point_summaries.csv"
))
production_wide <- r2_production |>
  select("run_id", "measure", "estimate") |>
  tidyr::pivot_wider(names_from = "measure", values_from = "estimate") |>
  rename_with(
    ~ paste0("production_", .x),
    -"run_id"
  )
point_compare <- point_r2 |>
  inner_join(production_wide, by = "run_id", relationship = "one-to-one")
measure_columns <- c(
  "marginal_r2", "conditional_r2", "participant_associated_share",
  "site_part_r2", "photoperiod_part_r2",
  "latitude_model_marginal_r2", "latitude_part_r2",
  "unrepresented_share"
)
stopifnot(all(vapply(measure_columns, function(column) {
  isTRUE(all.equal(
    point_compare[[column]],
    point_compare[[paste0("production_", column)]],
    tolerance = 1e-14,
    check.attributes = FALSE
  ))
}, logical(1))))

gate_tests <- read_csv_strict(file.path(
  audit_root,
  paste0(
    "author_gate_post_repair/",
    "H01_METRIC-010_provisional_model_level_tests.csv"
  )
))
comparison <- inner_join(
  gate_tests |>
    select(
      "run_id", "metric_order", "family_id",
      gate_p_adjusted = "p_adjusted"
    ),
  tests_merged |>
    select(
      "run_id", "metric_order", "family_id",
      current_p_adjusted = "p_adjusted"
    ),
  by = c("run_id", "metric_order", "family_id"),
  relationship = "one-to-one"
) |>
  mutate(
    gate_supported = .data$gate_p_adjusted < 0.05,
    current_supported = .data$current_p_adjusted < 0.05,
    disposition_changed = .data$gate_supported != .data$current_supported
  )
if (any(comparison$disposition_changed, na.rm = TRUE)) {
  stop("A complete-family support disposition differs from the accepted gate", call. = FALSE)
}

primary_counts <- tests_merged |>
  filter(.data$run_id == "main__glasses__all_available") |>
  group_by(.data$family_id) |>
  summarise(supported = sum(.data$p_adjusted < 0.05), .groups = "drop")
expected_counts <- c(
  `H01-F1-site` = 10L,
  `H01-F2-photoperiod` = 12L,
  `H01-F3-latitude` = 7L,
  `H01-F4-site-latitude-adequacy` = 9L
)
observed_counts <- setNames(primary_counts$supported, primary_counts$family_id)
stopifnot(identical(observed_counts[names(expected_counts)], expected_counts))

# Assemble the aggregate fit-results object from the same merged tables.
fit_results_path <- file.path(root, "artifacts/07_models/H01/H01_fit_results.rds")
fit_results <- readRDS(fit_results_path)
fit_map <- c(
  tests = "H01_model_level_tests.csv",
  term_effects = "H01_term_effects.csv",
  site_estimates = "H01_site_estimates.csv",
  site_deviations = "H01_site_deviations.csv",
  marginalization = "H01_marginalization_comparison.csv",
  samples = "H01_exact_samples.csv",
  samples_by_site = "H01_exact_samples_by_site.csv",
  diagnostics = "H01_model_diagnostics.csv",
  influence = "H01_participant_influence.csv",
  latitude_loo = "H01_latitude_leave_one_site_out.csv",
  random_site = "H01_random_site_descriptions.csv",
  r2_point = "H01_r2_point_summaries.csv",
  model_manifest = "H01_model_manifest.csv",
  preregistered_scope = "H01_preregistered_scope_sensitivity.csv"
)
for (component in names(fit_map)) {
  fit_results[[component]] <- merged[[fit_map[[component]]]]
}

write_candidate_csv <- function(data, relative_path) {
  path <- file.path(candidate_root, relative_path)
  write_csv_artifact(data, path, producer = producer)
  path
}
write_candidate_rds <- function(object, relative_path) {
  path <- file.path(candidate_root, relative_path)
  write_rds_artifact(object, path, producer = producer)
  path
}

candidate_paths <- character()
table_names <- c(names(table_specs), tests_name, scope_name, r2_name)
for (name in unique(table_names)) {
  candidate_paths <- c(candidate_paths, write_candidate_csv(
    merged[[name]],
    file.path("artifacts/09_tables/H01", name)
  ))
}
for (name in c(names(diagnostic_specs), bootstrap_name, failure_name)) {
  candidate_paths <- c(candidate_paths, write_candidate_csv(
    merged[[name]],
    file.path("artifacts/08_diagnostics/H01", name)
  ))
}
candidate_paths <- c(candidate_paths, write_candidate_rds(
  fit_results,
  "artifacts/07_models/H01/H01_fit_results.rds"
))

# Copy the accepted point bundles and production draws into the candidate.
copy_candidate <- function(from, relative_path) {
  to <- file.path(candidate_root, relative_path)
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(from, to, overwrite = TRUE, copy.mode = TRUE)) {
    stop("Could not copy candidate artifact: ", from, call. = FALSE)
  }
  to
}
per_run_candidate_paths <- character()
for (run_id in target_runs) {
  parts <- strsplit(run_id, "__", fixed = TRUE)[[1L]]
  relative_directory <- file.path(
    "H01", parts[[1L]], parts[[2L]], parts[[3L]]
  )
  point_specs <- c(
    file.path("artifacts/07_models", relative_directory, paste0(metric_id, "_model_frame.rds")),
    file.path("artifacts/07_models", relative_directory, paste0(metric_id, "_models.rds")),
    file.path("artifacts/08_diagnostics", relative_directory, paste0(metric_id, "_diagnostics.png")),
    file.path("artifacts/11_source_data", relative_directory, paste0(metric_id, "_diagnostic_plot_data.csv")),
    file.path("artifacts/11_source_data", relative_directory, paste0(metric_id, "_model_frame.csv"))
  )
  for (relative_path in point_specs) {
    per_run_candidate_paths <- c(
      per_run_candidate_paths,
      copy_candidate(file.path(point_root, relative_path), relative_path)
    )
  }
  draw_relative <- file.path(
    "artifacts/07_models", relative_directory,
    paste0(metric_id, "_r2_bootstrap_draws.rds")
  )
  draw_source <- file.path(
    production_root, "draws", parts[[1L]], parts[[2L]], parts[[3L]],
    paste0(metric_id, "_draws.rds")
  )
  per_run_candidate_paths <- c(
    per_run_candidate_paths,
    copy_candidate(draw_source, draw_relative)
  )
}
candidate_paths <- c(candidate_paths, per_run_candidate_paths)

# Record the exact pre-install non-MDER boundary. This intentionally uses the
# current accepted post-METRIC-011 files rather than the older METRIC-010 gate
# snapshot.
non_mder_roots <- file.path(
  root,
  c("artifacts/07_models/H01", "artifacts/08_diagnostics/H01", "artifacts/11_source_data/H01")
)
all_scientific_files <- sort(unique(unlist(lapply(
  non_mder_roots,
  list.files,
  recursive = TRUE,
  full.names = TRUE
))))
all_scientific_files <- all_scientific_files[
  file.exists(all_scientific_files) & !dir.exists(all_scientific_files)
]
non_mder_files <- all_scientific_files[
  !grepl(old_metric_id, all_scientific_files, fixed = TRUE) &
    !grepl(metric_id, all_scientific_files, fixed = TRUE) &
    basename(all_scientific_files) != "H01_fit_results.rds" &
    !basename(all_scientific_files) %in% c(
      "H01_model_diagnostics.csv", "H01_participant_influence.csv",
      "H01_latitude_leave_one_site_out.csv", "H01_r2_bootstrap_audit.csv",
      "H01_r2_bootstrap_failures.csv"
    )
]
non_mder_baseline <- tibble::tibble(
  path = relative_to_root(non_mder_files),
  sha256 = unname(vapply(non_mder_files, artifact_sha256, character(1))),
  bytes = as.numeric(file.info(non_mder_files)$size)
)
baseline_path <- file.path(
  integration_root,
  "H01_METRIC-010_non_mder_preintegration_baseline.csv"
)
write_csv_artifact(non_mder_baseline, baseline_path, producer = producer)

support_path <- file.path(
  integration_root,
  "H01_METRIC-010_support_disposition.csv"
)
write_csv_artifact(comparison, support_path, producer = producer)

candidate_manifest <- bind_rows(lapply(sort(candidate_paths), function(path) {
  candidate_path <- path
  tibble::tibble(
    path = substring(candidate_path, nchar(candidate_root) + 2L),
    sha256 = artifact_sha256(candidate_path),
    bytes = as.numeric(file.info(candidate_path)$size),
    role = "H01 METRIC-010 integration candidate",
    producer = producer,
    r_version = as.character(getRversion())
  )
}))
candidate_manifest_path <- file.path(
  integration_root,
  "H01_METRIC-010_integration_candidate_manifest.csv"
)
write_csv_artifact(candidate_manifest, candidate_manifest_path, producer = producer)

message(
  "H01 METRIC-010 integration candidate passed: 8 MDER targets, ",
  "64 production interval rows, no support disposition change versus the ",
  "accepted point gate, and no canonical artifact replaced"
)
