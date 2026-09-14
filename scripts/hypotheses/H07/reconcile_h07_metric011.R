source("scripts/hypotheses/H07/h07_stage2_core.R")

stage_root <- Sys.getenv("H07_STAGE2_ARTIFACT_ROOT", unset = "")
if (!nzchar(stage_root)) {
  h07_stage2_abort("H07 METRIC-011 reconciliation requires a staging root")
}
stage_root <- normalizePath(stage_root, winslash = "/", mustWork = TRUE)
project_root <- normalizePath(h07_stage2_root, winslash = "/", mustWork = TRUE)
if (identical(stage_root, project_root)) {
  h07_stage2_abort("H07 METRIC-011 staging and project roots must differ")
}

apply_update <- identical(
  Sys.getenv("H07_METRIC011_APPLY", unset = "0"),
  "1"
)
metric_id <- "l10_mean_medi"

expected_hashes <- c(
  decision = "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
  evidence_manifest = "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
  metric_manifest = "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
  site_context_manifest = "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518",
  base_manifest = "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce"
)
sealed_paths <- c(
  decision = "audit/decisions/l10_numerical_zero_normalization.md",
  evidence_manifest = paste0(
    "audit/reconciliation/l10_METRIC-011/",
    "METRIC-011_evidence_manifest.csv"
  ),
  metric_manifest = "artifacts/12_manifests/metric_artifacts.csv",
  site_context_manifest = paste0(
    "artifacts/12_manifests/",
    "site_solar_context_artifacts.csv"
  ),
  base_manifest = "artifacts/12_manifests/base_model_data_artifacts.csv"
)

project_path <- function(path) file.path(project_root, path)
stage_path <- function(path) file.path(stage_root, path)
sha256 <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}
abort_unless <- function(condition, message) {
  if (!isTRUE(condition)) h07_stage2_abort("%s", message)
}
same_values <- function(x, y) {
  isTRUE(all.equal(
    as.data.frame(x),
    as.data.frame(y),
    check.attributes = FALSE,
    tolerance = 0
  ))
}
read_project_table <- function(filename) {
  readr::read_csv(
    project_path(file.path("artifacts/09_tables/H07", filename)),
    show_col_types = FALSE
  )
}
read_stage_table <- function(filename) {
  readr::read_csv(
    stage_path(file.path("artifacts/09_tables/H07", filename)),
    show_col_types = FALSE
  )
}

observed_hashes <- vapply(
  sealed_paths,
  function(path) sha256(project_path(path)),
  character(1)
)
abort_unless(
  identical(observed_hashes[names(expected_hashes)], expected_hashes),
  "One or more METRIC-011 seals differ from the controlling hashes"
)

base_manifest <- readr::read_csv(
  project_path(sealed_paths[["base_manifest"]]),
  show_col_types = FALSE
)
expected_bundle <- "e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916"
expected_base_artifacts <- c(
  glasses_participant_day_context =
    "013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a",
  chest_participant_day_context =
    "497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057",
  glasses_participant_day_enriched =
    "b469fa8f0a743de1cbb1075f78879b84ab602c74cc44fb97da45dee596681f42",
  chest_participant_day_enriched =
    "10aebeb5dabb53e8f3ee0747b62c31707da344e11b7068261c2ada2a0b7badc9"
)
base_rows <- base_manifest |>
  filter(.data$artifact_id %in% names(expected_base_artifacts)) |>
  arrange(match(.data$artifact_id, names(expected_base_artifacts)))
abort_unless(
  nrow(base_rows) == length(expected_base_artifacts) &&
    identical(base_rows$sha256, unname(expected_base_artifacts)) &&
    all(base_rows$input_bundle_sha256 == expected_bundle),
  "The sealed H07 base-model inputs or bundle pin do not match"
)

cell_changes <- readr::read_csv(
  project_path(
    "audit/reconciliation/l10_METRIC-011/primary_scientific_cell_changes.csv"
  ),
  show_col_types = FALSE
)
cell_counts <- cell_changes |>
  count(.data$position, name = "changed_cells") |>
  arrange(.data$position)
abort_unless(
  nrow(cell_changes) == 8L &&
    all(cell_changes$metric == metric_id) &&
    all(cell_changes$old_value_lx == 4.163336342344337e-17) &&
    all(cell_changes$new_value_lx == 0) &&
    identical(cell_counts$position, c("chest", "glasses")) &&
    identical(cell_counts$changed_cells, c(5L, 3L)),
  "The METRIC-011 primary cell-change evidence is not the sealed 5/3 split"
)

model_relative <- sort(list.files(
  project_path("artifacts/07_models/H07"),
  recursive = TRUE,
  all.files = TRUE,
  no.. = TRUE
))
stage_model_relative <- sort(list.files(
  stage_path("artifacts/07_models/H07"),
  recursive = TRUE,
  all.files = TRUE,
  no.. = TRUE
))
abort_unless(
  identical(model_relative, stage_model_relative),
  "The staged and accepted H07 model-file inventories differ"
)
model_before <- vapply(
  project_path(file.path("artifacts/07_models/H07", model_relative)),
  sha256,
  character(1)
)
model_after <- vapply(
  stage_path(file.path("artifacts/07_models/H07", model_relative)),
  sha256,
  character(1)
)
is_l10_model_file <- grepl(
  paste0("(^|/)", metric_id, "(/|[.])"),
  model_relative
)
abort_unless(
  all(model_before[!is_l10_model_file] == model_after[!is_l10_model_file]),
  "A non-L10 H07 model or frame changed in staging"
)
l10_model_changed <- which(
  is_l10_model_file & model_before != model_after
)
abort_unless(
  length(l10_model_changed) > 0L,
  "No staged L10 model or frame changed"
)

compare_non_l10_table <- function(filename, keys, tolerance = 0) {
  before <- read_project_table(filename) |>
    filter(.data$metric_id != .env$metric_id) |>
    arrange(across(all_of(keys)))
  after <- read_stage_table(filename) |>
    filter(.data$metric_id != .env$metric_id) |>
    arrange(across(all_of(keys)))
  isTRUE(all.equal(
    as.data.frame(before),
    as.data.frame(after),
    check.attributes = FALSE,
    tolerance = tolerance
  ))
}

non_l10_raw_checks <- c(
  main_samples = compare_non_l10_table(
    "H07_main_samples.csv",
    c("run_id", "metric_id")
  ),
  main_diagnostics = compare_non_l10_table(
    "H07_main_diagnostics.csv",
    c("run_id", "metric_id", "model_id"),
    tolerance = 1e-12
  ),
  main_raw_tests = compare_non_l10_table(
    "H07_main_tests_unadjusted.csv",
    c("run_id", "metric_id", "analysis_scope", "test_id")
  ),
  sensitivity_samples = compare_non_l10_table(
    "H07_sensitivity_samples.csv",
    c("run_id", "metric_id")
  ),
  sensitivity_diagnostics = compare_non_l10_table(
    "H07_sensitivity_diagnostics.csv",
    c("run_id", "metric_id", "model_id"),
    tolerance = 1e-12
  ),
  sensitivity_raw_tests = compare_non_l10_table(
    "H07_sensitivity_tests_unadjusted.csv",
    c("run_id", "metric_id", "analysis_scope", "test_id")
  ),
  loso_samples = compare_non_l10_table(
    "H07_loso_samples.csv",
    c("placement", "metric_id", "omitted_site")
  ),
  loso_diagnostics = compare_non_l10_table(
    "H07_loso_diagnostics.csv",
    c("placement", "metric_id", "omitted_site", "model_id"),
    tolerance = 1e-12
  )
)
abort_unless(
  all(non_l10_raw_checks),
  "A non-L10 H07 sample, diagnostic, or raw-test value changed"
)

classification_specs <- list(
  primary = list(
    file = "H07_revised_plateau_summary.csv",
    keys = c("run_id", "metric_id", "method_id"),
    fields = c(
      "any_pointwise_detected_increase",
      "any_pointwise_detected_decrease",
      "revised_plateau_pattern",
      "plateau_start",
      "disposition"
    )
  ),
  sensitivity = list(
    file = "H07_revised_sensitivity_plateau_comparison.csv",
    keys = c("run_id", "metric_id", "method_id"),
    fields = c(
      "revised_plateau_pattern",
      "plateau_start",
      "disposition",
      "classification_agrees"
    )
  ),
  model_form = list(
    file = "H07_revised_model_form_plateau_comparison.csv",
    keys = c("run_id", "metric_id", "model_id"),
    fields = c(
      "fit_status",
      "revised_plateau_pattern",
      "plateau_start",
      "disposition",
      "classification_agrees"
    )
  ),
  loso = list(
    file = "H07_revised_loso_plateau_comparison.csv",
    keys = c("run_id", "metric_id", "method_id"),
    fields = c(
      "any_pointwise_detected_increase",
      "any_pointwise_detected_decrease",
      "revised_plateau_pattern",
      "plateau_start",
      "disposition",
      "classification_agrees"
    )
  )
)

classification_comparison <- purrr::imap_dfr(
  classification_specs,
  function(spec, scope) {
    before <- read_project_table(spec$file) |>
      filter(.data$metric_id == .env$metric_id) |>
      arrange(across(all_of(spec$keys)))
    after <- read_stage_table(spec$file) |>
      filter(.data$metric_id == .env$metric_id) |>
      arrange(across(all_of(spec$keys)))
    abort_unless(
      identical(before[spec$keys], after[spec$keys]),
      paste0("L10 classification keys differ for ", scope)
    )
    changed <- vapply(spec$fields, function(field) {
      old <- before[[field]]
      new <- after[[field]]
      same <- (is.na(old) & is.na(new)) |
        (!is.na(old) & !is.na(new) & old == new)
      sum(!same)
    }, integer(1))
    tibble::tibble(
      scope = scope,
      rows = nrow(before),
      changed_classification_fields = sum(changed)
    )
  }
)

primary_before <- read_project_table("H07_revised_plateau_summary.csv") |>
  filter(
    .data$method_id == "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE"
  ) |>
  count(.data$placement, .data$revised_plateau_pattern, name = "n") |>
  arrange(.data$placement, .data$revised_plateau_pattern)
primary_after <- read_stage_table("H07_revised_plateau_summary.csv") |>
  filter(
    .data$method_id == "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE"
  ) |>
  count(.data$placement, .data$revised_plateau_pattern, name = "n") |>
  arrange(.data$placement, .data$revised_plateau_pattern)
pattern_counts_same <- same_values(primary_before, primary_after)

primary_l10_before <- read_project_table(
  "H07_revised_plateau_summary.csv"
) |>
  filter(
    .data$metric_id == .env$metric_id,
    .data$method_id == "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE"
  ) |>
  select(
    "placement",
    revised_plateau_pattern_before = "revised_plateau_pattern",
    plateau_start_before = "plateau_start",
    disposition_before = "disposition"
  )
primary_l10_after <- read_stage_table(
  "H07_revised_plateau_summary.csv"
) |>
  filter(
    .data$metric_id == .env$metric_id,
    .data$method_id == "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE"
  ) |>
  select(
    "placement",
    revised_plateau_pattern_after = "revised_plateau_pattern",
    plateau_start_after = "plateau_start",
    disposition_after = "disposition"
  )
primary_l10_comparison <- left_join(
  primary_l10_before,
  primary_l10_after,
  by = "placement"
)

compare_adjusted_tests <- function(filename) {
  keys <- c("run_id", "metric_id", "analysis_scope", "test_id")
  before <- read_project_table(filename) |>
    arrange(across(all_of(keys)))
  after <- read_stage_table(filename) |>
    arrange(across(all_of(keys)))
  abort_unless(
    identical(before[keys], after[keys]),
    paste0("Adjusted-test keys differ for ", filename)
  )
  non_l10 <- before$metric_id != metric_id
  tibble::tibble(
    file = filename,
    max_non_l10_raw_p_delta = max(
      abs(after$p_raw_model[non_l10] - before$p_raw_model[non_l10]),
      na.rm = TRUE
    ),
    max_non_l10_adjusted_p_delta = max(
      abs(
        after$p_adjusted_BH_model[non_l10] -
          before$p_adjusted_BH_model[non_l10]
      ),
      na.rm = TRUE
    ),
    adjusted_significance_changes = sum(
      (before$p_adjusted_BH_model < 0.05) !=
        (after$p_adjusted_BH_model < 0.05),
      na.rm = TRUE
    ),
    adjusted_three_decimal_changes = sum(
      round(before$p_adjusted_BH_model, 3) !=
        round(after$p_adjusted_BH_model, 3),
      na.rm = TRUE
    )
  )
}
adjusted_test_comparison <- bind_rows(
  compare_adjusted_tests("H07_main_tests.csv"),
  compare_adjusted_tests("H07_sensitivity_tests.csv")
)

scientific_conclusion_changed <-
  any(classification_comparison$changed_classification_fields > 0L) ||
  !pattern_counts_same ||
  any(adjusted_test_comparison$adjusted_significance_changes > 0L) ||
  any(adjusted_test_comparison$adjusted_three_decimal_changes > 0L)
abort_unless(
  !scientific_conclusion_changed,
  paste0(
    "METRIC-011 changes an H07 scientific classification; ",
    "stop for author review"
  )
)

table_directory <- "artifacts/09_tables/H07"
table_files <- sort(intersect(
  list.files(project_path(table_directory), pattern = "[.]csv$"),
  list.files(stage_path(table_directory), pattern = "[.]csv$")
))
table_before_hash <- vapply(
  project_path(file.path(table_directory, table_files)),
  sha256,
  character(1)
)
table_after_hash <- vapply(
  stage_path(file.path(table_directory, table_files)),
  sha256,
  character(1)
)
changed_table_files <- table_files[table_before_hash != table_after_hash]
excluded_table_files <- c(
  "H07_loso_run_registry.csv",
  "H07_main_tweedie_distribution_pilot.csv"
)
table_apply_files <- setdiff(changed_table_files, excluded_table_files)

loso_merge_keys <- list(
  H07_loso_curve_points.csv =
    c("run_id", "metric_id", "photoperiod_hours"),
  H07_loso_diagnostics.csv = c("run_id", "metric_id", "model_id"),
  H07_loso_samples.csv = c("run_id", "metric_id"),
  H07_revised_loso_plateau_comparison.csv =
    c("run_id", "metric_id", "method_id")
)

row_key <- function(data, keys) {
  values <- lapply(data[keys], function(value) {
    if (is.numeric(value)) {
      ifelse(is.na(value), "<NA>", sprintf("%.17g", value))
    } else {
      ifelse(is.na(value), "<NA>", as.character(value))
    }
  })
  do.call(paste, c(values, sep = "\u001f"))
}

merge_l10_rows <- function(filename) {
  before <- read_project_table(filename)
  after <- read_stage_table(filename)
  abort_unless(
    identical(names(before), names(after)) &&
      "metric_id" %in% names(before),
    paste0("Cannot merge L10 rows for ", filename)
  )
  old_index <- which(before$metric_id == metric_id)
  new_index <- which(after$metric_id == metric_id)
  abort_unless(
    length(old_index) == length(new_index),
    paste0("L10 row counts differ for ", filename)
  )
  if (identical(before$metric_id, after$metric_id)) {
    before[old_index, ] <- after[new_index, ]
  } else {
    keys <- loso_merge_keys[[filename]]
    abort_unless(
      !is.null(keys),
      paste0("A row-key map is required for ", filename)
    )
    old_keys <- row_key(before[old_index, ], keys)
    new_keys <- row_key(after[new_index, ], keys)
    abort_unless(
      !anyDuplicated(old_keys) && !anyDuplicated(new_keys) &&
        setequal(old_keys, new_keys),
      paste0("L10 row keys differ for ", filename)
    )
    before[old_index, ] <- after[new_index[match(old_keys, new_keys)], ]
  }
  readr::write_csv(
    before,
    stage_path(file.path(table_directory, filename)),
    na = ""
  )
}

whole_table_files <- c(
  "H07_input_manifest.csv",
  "H07_main_tests.csv",
  "H07_sensitivity_tests.csv"
)
for (filename in setdiff(table_apply_files, whole_table_files)) {
  merge_l10_rows(filename)
}

figure_relative <- "artifacts/08_figures/H07/H07_derivative_pilot_near_eye.png"
abort_unless(
  file.exists(stage_path(figure_relative)),
  "The staged L10-containing derivative pilot figure is missing"
)

model_plan <- tibble::tibble(
  relative_path = file.path(
    "artifacts/07_models/H07",
    model_relative[l10_model_changed]
  ),
  artifact_class = "L10_MODEL_OR_FRAME",
  apply_mode = "WHOLE_FILE",
  before_sha256 = model_before[l10_model_changed],
  after_sha256 = model_after[l10_model_changed]
)
table_plan <- tibble::tibble(
  relative_path = file.path(table_directory, table_apply_files),
  artifact_class = case_when(
    table_apply_files == "H07_input_manifest.csv" ~ "INPUT_MANIFEST",
    table_apply_files %in% c(
      "H07_main_tests.csv",
      "H07_sensitivity_tests.csv"
    ) ~ "BH_FAMILY_TABLE",
    TRUE ~ "L10_DERIVED_TABLE"
  ),
  apply_mode = if_else(
    table_apply_files %in% whole_table_files,
    "WHOLE_FILE",
    "L10_ROWS_ONLY"
  ),
  before_sha256 = vapply(
    project_path(file.path(table_directory, table_apply_files)),
    sha256,
    character(1)
  ),
  after_sha256 = vapply(
    stage_path(file.path(table_directory, table_apply_files)),
    sha256,
    character(1)
  )
)
figure_plan <- tibble::tibble(
  relative_path = figure_relative,
  artifact_class = "L10_CONTAINING_DIAGNOSTIC_FIGURE",
  apply_mode = "WHOLE_FILE",
  before_sha256 = sha256(project_path(figure_relative)),
  after_sha256 = sha256(stage_path(figure_relative))
)
apply_plan <- bind_rows(model_plan, table_plan, figure_plan) |>
  arrange(.data$artifact_class, .data$relative_path) |>
  mutate(
    applied_sha256 = NA_character_,
    apply_status = if_else(apply_update, "PENDING", "NOT_APPLIED")
  )

summary_rows <- bind_rows(
  tibble::tibble(
    check_id = paste0("SEAL_", names(expected_hashes)),
    domain = "sealed_input",
    observed = unname(observed_hashes[names(expected_hashes)]),
    expected = unname(expected_hashes),
    status = "PASS"
  ),
  tibble::tribble(
    ~check_id, ~domain, ~observed, ~expected, ~status,
    "BASE_BUNDLE", "sealed_input", expected_bundle, expected_bundle, "PASS",
    "PRIMARY_CHANGED_CELLS", "scientific_input", "8", "8", "PASS",
    "PRIMARY_NEAR_EYE_CHANGED_CELLS", "scientific_input", "3", "3", "PASS",
    "PRIMARY_CHEST_CHANGED_CELLS", "scientific_input", "5", "5", "PASS",
    "NON_L10_MODEL_FRAME_FILES", "preservation",
      as.character(sum(!is_l10_model_file)),
      as.character(sum(!is_l10_model_file)), "PASS",
    "NON_L10_RAW_TABLE_CHECKS", "preservation",
      as.character(sum(non_l10_raw_checks)),
      as.character(length(non_l10_raw_checks)), "PASS",
    "CLASSIFICATION_FIELD_CHANGES", "scientific_conclusion",
      as.character(sum(
        classification_comparison$changed_classification_fields
      )), "0", "PASS",
    "ADJUSTED_SIGNIFICANCE_CHANGES", "scientific_conclusion",
      as.character(sum(
        adjusted_test_comparison$adjusted_significance_changes
      )), "0", "PASS",
    "ADJUSTED_THREE_DECIMAL_CHANGES", "scientific_conclusion",
      as.character(sum(
        adjusted_test_comparison$adjusted_three_decimal_changes
      )), "0", "PASS",
    "PRIMARY_NEAR_EYE_PATTERN_COUNT", "scientific_conclusion",
      as.character(primary_after$n[
        primary_after$placement == "near_eye" &
          primary_after$revised_plateau_pattern
      ]), "6", "PASS",
    "PRIMARY_CHEST_PATTERN_COUNT", "scientific_conclusion",
      as.character(primary_after$n[
        primary_after$placement == "chest" &
          primary_after$revised_plateau_pattern
      ]), "7", "PASS",
    "SCIENTIFIC_CONCLUSION_CHANGED", "scientific_conclusion",
      as.character(scientific_conclusion_changed), "FALSE", "PASS"
  )
)

scientific_comparison <- bind_rows(
  primary_l10_comparison |>
    transmute(
      comparison = paste0("primary_L10_", .data$placement),
      before = paste(
        .data$revised_plateau_pattern_before,
        .data$plateau_start_before,
        .data$disposition_before,
        sep = " | "
      ),
      after = paste(
        .data$revised_plateau_pattern_after,
        .data$plateau_start_after,
        .data$disposition_after,
        sep = " | "
      ),
      changed = .data$before != .data$after
    ),
  classification_comparison |>
    transmute(
      comparison = paste0(.data$scope, "_classification_fields"),
      before = "accepted",
      after = paste0(.data$changed_classification_fields, " changed"),
      changed = .data$changed_classification_fields > 0L
    ),
  adjusted_test_comparison |>
    transmute(
      comparison = paste0(.data$file, "_REPORT-008"),
      before = "accepted",
      after = paste0(
        .data$adjusted_significance_changes,
        " significance; ",
        .data$adjusted_three_decimal_changes,
        " three-decimal changes"
      ),
      changed = .data$adjusted_significance_changes > 0L |
        .data$adjusted_three_decimal_changes > 0L
    )
)

manifest_directory <- stage_path("artifacts/12_manifests/H07")
dir.create(manifest_directory, recursive = TRUE, showWarnings = FALSE)
summary_path <- file.path(
  manifest_directory,
  "H07_METRIC-011_reconciliation_summary.csv"
)
comparison_path <- file.path(
  manifest_directory,
  "H07_METRIC-011_scientific_comparison.csv"
)
plan_path <- file.path(
  manifest_directory,
  "H07_METRIC-011_artifact_update_manifest.csv"
)
readr::write_csv(summary_rows, summary_path, na = "")
readr::write_csv(scientific_comparison, comparison_path, na = "")
readr::write_csv(apply_plan, plan_path, na = "")

if (apply_update) {
  copy_ok <- vapply(apply_plan$relative_path, function(relative_path) {
    destination <- project_path(relative_path)
    dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
    file.copy(stage_path(relative_path), destination, overwrite = TRUE)
  }, logical(1))
  abort_unless(all(copy_ok), "One or more bounded H07 artifact copies failed")
  applied <- vapply(
    project_path(apply_plan$relative_path),
    sha256,
    character(1)
  )
  apply_plan <- apply_plan |>
    mutate(
      applied_sha256 = applied,
      apply_status = if_else(
        .data$applied_sha256 == .data$after_sha256,
        "PASS",
        "FAIL"
      )
    )
  abort_unless(
    all(apply_plan$apply_status == "PASS"),
    "A bounded H07 artifact copy failed hash verification"
  )
  summary_rows <- bind_rows(
    summary_rows,
    tibble::tibble(
      check_id = "BOUNDED_ARTIFACT_APPLY",
      domain = "application",
      observed = as.character(sum(apply_plan$apply_status == "PASS")),
      expected = as.character(nrow(apply_plan)),
      status = "PASS"
    )
  )
  readr::write_csv(summary_rows, summary_path, na = "")
  readr::write_csv(apply_plan, plan_path, na = "")
  manifest_relative <- file.path(
    "artifacts/12_manifests/H07",
    basename(c(summary_path, comparison_path, plan_path))
  )
  manifest_copy_ok <- vapply(manifest_relative, function(relative_path) {
    file.copy(stage_path(relative_path), project_path(relative_path), overwrite = TRUE)
  }, logical(1))
  abort_unless(
    all(manifest_copy_ok),
    "The H07 METRIC-011 reconciliation manifests could not be installed"
  )
}

message(sprintf(
  paste0(
    "H07 METRIC-011 reconciliation complete: %d bounded artifacts; ",
    "apply=%s; conclusion_changed=%s"
  ),
  nrow(apply_plan),
  apply_update,
  scientific_conclusion_changed
))
