source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/metric_display_registry.R")
source("scripts/pipeline/preanalysis_comparison.R")
source("scripts/pipeline/build_preanalysis_comparison.R")
source("scripts/pipeline/verify_preanalysis_comparison_artifacts.R")

Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE, warn = 2)

expected_normalization_sha256 <-
  "e3d484711abb54f69d63ff302e5a0329efda3fd0a8c85feaf9cc4f850005c9ab"
expected_base_sha256 <-
  "fd48dc5d1ecd5da125dd2c360c32239f0adfe7009eca881f5838b0e61b81b13d"
expected_base_input_bundle_sha256 <-
  "b6262d925937f505514834ea9d5b733a6be76c00b1a8ec6855a9a10947bfb900"

test_preanalysis_expect_error <- function(expression, pattern) {
  observed <- tryCatch(
    {
      force(expression)
      ""
    },
    error = function(error) conditionMessage(error)
  )
  stopifnot(
    nzchar(observed),
    grepl(pattern, observed, fixed = TRUE)
  )
  invisible(observed)
}

test_preanalysis_fixture <- function(
  value,
  local_date = NULL,
  site = "TEST"
) {
  n <- length(value)
  data.frame(
    site = rep(site, n),
    Id = sprintf("P%02d", seq_len(n)),
    value = value,
    local_date = if (is.null(local_date)) {
      as.Date(rep(NA_character_, n))
    } else {
      as.Date(local_date)
    },
    stringsAsFactors = FALSE
  )
}

message("Testing variable-specific linear clock-axis transformations")
stopifnot(
  identical(
    preanalysis_transform_value(
      c(0, 719, 720, 1439),
      "clock_minute_to_centered_decimal_hour"
    ),
    c(0, 719 / 60, -12, 1439 / 60 - 24)
  )
)

crosswalk <- preanalysis_attach_metric_display(
  preanalysis_variable_crosswalk(),
  project_root()
)
dates <- as.Date(c("2026-01-01", "2026-01-02", "2026-01-03"))
numeric_crosswalk <- crosswalk$value_type == "numeric"
l10_centered <- crosswalk$variable_id == "light_l10_midpoint"
discarded_clock_metric <- c(
  "light_m10_onset",
  "light_m10_offset",
  "light_l10_onset",
  "light_l10_offset"
)
light_metric <- crosswalk$domain == "light_metric"
registry <- read_metric_display_registry(project_root())
duplicated_light_name <-
  duplicated(crosswalk$manuscript_name[light_metric]) |
  duplicated(crosswalk$manuscript_name[light_metric], fromLast = TRUE)
stopifnot(
  nrow(crosswalk) == 72L,
  !any(discarded_clock_metric %in% crosswalk$variable_id),
  !any(grepl(
    "(^|_)(m10|l10)_(onset|offset)($|_)",
    crosswalk$metric_id[light_metric],
    perl = TRUE
  )),
  setequal(crosswalk$metric_id[light_metric], registry$metric_id),
  all(nzchar(crosswalk$manuscript_name[light_metric])),
  all(nzchar(crosswalk$manuscript_category[light_metric])),
  all(nzchar(crosswalk$variant_label[light_metric][duplicated_light_name])),
  !anyDuplicated(paste(
    crosswalk$manuscript_name[light_metric],
    crosswalk$variant_label[light_metric],
    sep = " — "
  )),
  !any(grepl(
    "\\bMEDI\\b|melanopic[[:space:]-]+EDI",
    crosswalk$manuscript_name[light_metric],
    ignore.case = FALSE,
    perl = TRUE
  )),
  all(grepl(
    "melEDI",
    crosswalk$manuscript_name[
      light_metric &
        grepl("_above_|_below_", crosswalk$metric_id)
    ],
    fixed = TRUE
  )),
  !any(grepl(
    paste(
      "support[- ]aware|support[- ]corrected|time[- ]sensitive|",
      "ratio of integrals"
    ),
    paste(
      crosswalk$manuscript_name[light_metric],
      crosswalk$manuscript_category[light_metric]
    ),
    ignore.case = TRUE,
    perl = TRUE
  )),
  all(crosswalk$axis_geometry[numeric_crosswalk] == "linear"),
  all(
    crosswalk$difference_method[numeric_crosswalk] ==
      "linear_current_minus_baseline"
  ),
  all(
    crosswalk$canonical_transform[l10_centered] ==
      "clock_minute_to_centered_decimal_hour"
  ),
  all(crosswalk$baseline_transform[l10_centered] == "identity"),
  crosswalk$canonical_transform[
    crosswalk$variable_id == "light_m10_midpoint"
  ] ==
    "clock_minute_to_decimal_hour",
  crosswalk$baseline_transform[
    crosswalk$variable_id == "light_m10_midpoint"
  ] ==
    "identity",
  crosswalk$axis_geometry[
    crosswalk$variable_id == "participant_msf_sc"
  ] ==
    "linear"
)

message("Testing the model-ready endpoint firewall")
firewall_inputs <- list(
  participant_day_enriched = list(
    glasses = data.frame(retained = TRUE),
    chest = data.frame(retained = TRUE)
  )
)
preanalysis_assert_discarded_metric_firewall(
  firewall_inputs,
  crosswalk
)
leaking_inputs <- firewall_inputs
leaking_inputs$participant_day_enriched$glasses$m10_onset_clock_minute <-
  480
test_preanalysis_expect_error(
  preanalysis_assert_discarded_metric_firewall(
    leaking_inputs,
    crosswalk
  ),
  "Discarded M10/L10 onset/offset entered model-ready base data"
)

message("Testing exact numeric key reconciliation and paired differences")
numeric_specification <- crosswalk[
  crosswalk$variable_id == "day_photoperiod_hours",
  ,
  drop = FALSE
]
numeric_baseline_data <- test_preanalysis_fixture(c(8, 9, 10), dates)
numeric_canonical_data <- test_preanalysis_fixture(c(9, 11, 10), dates)
numeric_baseline <- preanalysis_value_rows(
  numeric_baseline_data,
  numeric_specification,
  series = "baseline",
  placement = "glasses",
  value = numeric_baseline_data$value,
  local_date = numeric_baseline_data$local_date
)
numeric_canonical <- preanalysis_value_rows(
  numeric_canonical_data,
  numeric_specification,
  series = "canonical",
  placement = "glasses",
  value = numeric_canonical_data$value,
  local_date = numeric_canonical_data$local_date
)
numeric_keys <- preanalysis_reconcile_keys(
  numeric_baseline,
  numeric_canonical,
  numeric_specification
)
numeric_paired <- preanalysis_paired_summary(
  numeric_baseline,
  numeric_canonical,
  numeric_specification
)
stopifnot(
  numeric_specification$comparability_class ==
    "exact_field_key_and_scale_mapping",
  numeric_keys$baseline_n_keys == 3L,
  numeric_keys$canonical_n_keys == 3L,
  numeric_keys$common_n_keys == 3L,
  numeric_keys$baseline_only_n_keys == 0L,
  numeric_keys$canonical_only_n_keys == 0L,
  numeric_paired$n_paired_observed == 3L,
  numeric_paired$mean_difference == 1,
  numeric_paired$median_difference == 1,
  numeric_paired$mean_absolute_difference == 1
)

message("Testing categorical paired agreement on common keys")
categorical_specification <- crosswalk[
  crosswalk$variable_id == "participant_site",
  ,
  drop = FALSE
]
categorical_baseline_data <- test_preanalysis_fixture(
  c("TUM", "MPI", "BAUA")
)
categorical_canonical_data <- test_preanalysis_fixture(
  c("TUM", "MPI", "TUM")
)
categorical_baseline <- preanalysis_value_rows(
  categorical_baseline_data,
  categorical_specification,
  series = "baseline",
  placement = "glasses",
  value = categorical_baseline_data$value
)
categorical_canonical <- preanalysis_value_rows(
  categorical_canonical_data,
  categorical_specification,
  series = "canonical",
  placement = "glasses",
  value = categorical_canonical_data$value
)
categorical_paired <- preanalysis_paired_summary(
  categorical_baseline,
  categorical_canonical,
  categorical_specification
)
stopifnot(
  categorical_paired$n_common_keys == 3L,
  categorical_paired$n_paired_observed == 3L,
  categorical_paired$n_equal == 2L,
  isTRUE(all.equal(categorical_paired$agreement_rate, 2 / 3))
)

message("Testing linear timing differences and distribution distances")
timing_specification <- crosswalk[
  crosswalk$variable_id == "light_first_timing_above_250",
  ,
  drop = FALSE
]
timing_dates <- as.Date("2026-02-01") + 0:3
timing_baseline_data <- test_preanalysis_fixture(
  c(23, 1, 6, 12),
  timing_dates
)
timing_canonical_data <- test_preanalysis_fixture(
  c(30, 120, 420, 780),
  timing_dates
)
timing_baseline <- preanalysis_value_rows(
  timing_baseline_data,
  timing_specification,
  series = "baseline",
  placement = "glasses",
  value = timing_baseline_data$value,
  local_date = timing_baseline_data$local_date
)
timing_canonical <- preanalysis_value_rows(
  timing_canonical_data,
  timing_specification,
  series = "canonical",
  placement = "glasses",
  value = timing_canonical_data$value,
  local_date = timing_canonical_data$local_date
)
timing_shape <- preanalysis_distribution_shape(
  timing_baseline,
  timing_canonical,
  timing_specification
)
timing_paired <- preanalysis_paired_summary(
  timing_baseline,
  timing_canonical,
  timing_specification
)
stopifnot(
  timing_shape$axis_geometry == "linear",
  timing_specification$difference_method == "linear_current_minus_baseline",
  is.finite(timing_shape$baseline_bowley_skew),
  is.finite(timing_shape$canonical_bowley_skew),
  is.finite(timing_shape$baseline_tail_asymmetry),
  is.finite(timing_shape$canonical_tail_asymmetry),
  is.finite(timing_shape$ecdf_max_distance),
  is.finite(timing_shape$wasserstein_1),
  is.finite(timing_shape$wasserstein_1_iqr_scaled),
  is.na(timing_shape$circular_kuiper_distance),
  isTRUE(all.equal(timing_paired$mean_difference, -4.875))
)

message("Testing canonical-only variables remain explicitly not applicable")
new_metric_specification <- crosswalk[
  crosswalk$variable_id == "light_mder_ratio_of_integrals",
  ,
  drop = FALSE
]
new_metric_data <- test_preanalysis_fixture(c(0.5, 0.6, 0.7), dates)
new_metric_canonical <- preanalysis_value_rows(
  new_metric_data,
  new_metric_specification,
  series = "canonical",
  placement = "glasses",
  value = new_metric_data$value,
  local_date = new_metric_data$local_date
)
new_metric_keys <- preanalysis_reconcile_keys(
  NULL,
  new_metric_canonical,
  new_metric_specification
)
new_metric_paired <- preanalysis_paired_summary(
  NULL,
  new_metric_canonical,
  new_metric_specification
)
stopifnot(
  new_metric_specification$comparison_status ==
    "not_applicable_no_field_key_mapping",
  new_metric_specification$comparability_class ==
    "changed_estimand_or_no_direct_mapping_no_numerical_comparison",
  is.na(new_metric_keys$baseline_n_keys),
  new_metric_keys$canonical_n_keys == 3L,
  is.na(new_metric_keys$common_n_keys),
  is.na(new_metric_paired$n_common_keys),
  is.na(new_metric_paired$n_paired_observed),
  is.na(new_metric_paired$mean_difference)
)

message("Building the complete pre-analysis comparison twice")
project <- project_root()
first_output_root <- tempfile("preanalysis-comparison-first-")
second_output_root <- tempfile("preanalysis-comparison-second-")
dir.create(first_output_root, recursive = TRUE)
dir.create(second_output_root, recursive = TRUE)
first_build <- build_preanalysis_comparison_artifacts(
  root = project,
  output_root = first_output_root,
  expected_normalization_manifest_sha256 = expected_normalization_sha256,
  expected_base_manifest_sha256 = expected_base_sha256
)
second_build <- build_preanalysis_comparison_artifacts(
  root = project,
  output_root = second_output_root,
  expected_normalization_manifest_sha256 = expected_normalization_sha256,
  expected_base_manifest_sha256 = expected_base_sha256
)
stopifnot(
  identical(first_build$status, "PASS"),
  identical(second_build$status, "PASS"),
  nrow(first_build$crosswalk) == 72L,
  nrow(first_build$tables$overview) == 120L,
  !any(
    discarded_clock_metric %in%
      first_build$tables$overview$variable_id
  ),
  !any(
    discarded_clock_metric %in%
      first_build$tables$series_summary$variable_id
  ),
  !any(
    discarded_clock_metric %in%
      first_build$tables$numeric_figure_data$variable_id
  ),
  all(first_build$crosswalk$axis_geometry != "circular_24h"),
  all(vapply(
    first_build$tables$series_summary[c(
      "circular_mean",
      "circular_median",
      "circular_resultant_length",
      "circular_sd_hours"
    )],
    function(value) all(is.na(value)),
    logical(1)
  )),
  all(is.na(first_build$tables$shape$circular_kuiper_distance)),
  all(vapply(
    first_build$tables$overview[c(
      "canonical_circular_mean",
      "canonical_circular_median",
      "canonical_circular_resultant_length",
      "canonical_circular_sd_hours",
      "baseline_circular_mean",
      "baseline_circular_median",
      "baseline_circular_resultant_length",
      "baseline_circular_sd_hours",
      "circular_kuiper_distance"
    )],
    function(value) all(is.na(value)),
    logical(1)
  )),
  "light_l10_midpoint" %in%
    first_build$tables$numeric_figure_data$variable_id,
  "light_m10_midpoint" %in%
    first_build$tables$numeric_figure_data$variable_id,
  all(nzchar(
    first_build$tables$overview$manuscript_name[
      first_build$tables$overview$domain == "light_metric"
    ]
  )),
  all(nzchar(
    first_build$tables$overview$manuscript_category[
      first_build$tables$overview$domain == "light_metric"
    ]
  ))
)

message("Testing exact pinned hashes and byte-stable regeneration")
first_manifest <- first_build$manifest[
  order(first_build$manifest$artifact_id),
  ,
  drop = FALSE
]
second_manifest <- second_build$manifest[
  order(second_build$manifest$artifact_id),
  ,
  drop = FALSE
]
stopifnot(
  identical(
    first_manifest[c(
      "artifact_id",
      "artifact_type",
      "path",
      "sha256",
      "bytes",
      "rows",
      "columns",
      "producer",
      "r_version",
      "status"
    )],
    second_manifest[c(
      "artifact_id",
      "artifact_type",
      "path",
      "sha256",
      "bytes",
      "rows",
      "columns",
      "producer",
      "r_version",
      "status"
    )]
  ),
  first_build$run_metadata$value[
    first_build$run_metadata$field == "normalization_manifest_sha256"
  ] ==
    expected_normalization_sha256,
  first_build$run_metadata$value[
    first_build$run_metadata$field == "base_manifest_sha256"
  ] ==
    expected_base_sha256,
  first_build$run_metadata$value[
    first_build$run_metadata$field == "base_input_bundle_sha256"
  ] ==
    expected_base_input_bundle_sha256,
  first_build$run_metadata$value[
    first_build$run_metadata$field == "metric_display_registry_sha256"
  ] ==
    artifact_sha256(metric_display_registry_path(project)),
  nrow(first_build$input_provenance) == 20L,
  first_build$input_provenance$sha256[
    first_build$input_provenance$input_id == "metric_display_registry"
  ] ==
    artifact_sha256(metric_display_registry_path(project))
)

message("Testing diary quarantine visibility without fabricated days")
levels <- first_build$tables$categorical_levels
quarantined <- levels[
  levels$variable_id == "hour_interval_quarantined" &
    levels$series == "canonical" &
    levels$level == "TRUE",
  ,
  drop = FALSE
]
date_missing <- levels[
  levels$variable_id == "hour_diary_date_missing" &
    levels$series == "canonical" &
    levels$level == "TRUE",
  ,
  drop = FALSE
]
issue <- levels[
  levels$variable_id == "hour_interval_issue_code" &
    levels$series == "canonical" &
    levels$level == "missing_start_and_end",
  ,
  drop = FALSE
]
diary_summary <- first_build$tables$series_summary[
  first_build$tables$series_summary$variable_id == "hour_interval_quarantined" &
    first_build$tables$series_summary$series == "canonical",
  ,
  drop = FALSE
]
stopifnot(
  nrow(quarantined) == 1L,
  quarantined$n == 27L,
  quarantined$n_participant_days == 0L,
  nrow(date_missing) == 1L,
  date_missing$n == 27L,
  date_missing$n_participant_days == 0L,
  nrow(issue) == 1L,
  issue$n == 27L,
  issue$n_participant_days == 0L,
  diary_summary$n_observations == 30199L,
  diary_summary$n_estimable == 30199L,
  diary_summary$n_participant_days == 1364L
)

message("Testing explicit N/A baseline fields in the overview")
overview <- first_build$tables$overview
not_applicable <- overview$comparison_status ==
  "not_applicable_no_field_key_mapping"
baseline_fields <- grep(
  paste0(
    "^baseline_(",
    "n_|mean$|median$|sd$|iqr$|q|zero_rate$|nonfinite_rate$|",
    "circular_|bowley|tail_",
    ")"
  ),
  names(overview),
  value = TRUE
)
paired_fields <- c(
  "n_common_keys",
  "n_paired_observed",
  "mean_difference",
  "median_difference",
  "agreement_rate"
)
stopifnot(
  any(not_applicable),
  all(vapply(
    overview[not_applicable, baseline_fields, drop = FALSE],
    function(value) all(is.na(value)),
    logical(1)
  )),
  all(vapply(
    overview[not_applicable, paired_fields, drop = FALSE],
    function(value) all(is.na(value)),
    logical(1)
  )),
  all(
    first_build$tables$shape$distance_scope ==
      paste(
        "all_estimable_rows;",
        "numeric finite only;",
        "categorical missing retained as level"
      )
  )
)

message("Running the independent artifact verifier")
verification <- verify_preanalysis_comparison_artifacts(
  root = project,
  output_root = first_output_root,
  expected_normalization_manifest_sha256 = expected_normalization_sha256,
  expected_base_manifest_sha256 = expected_base_sha256
)
stopifnot(identical(verification$status, "PASS"))

message("Testing verifier rejection after artifact tampering")
overview_path <- first_build$paths$csv[["comparison_overview"]]
tampered_overview <- readr::read_csv(
  overview_path,
  show_col_types = FALSE,
  progress = FALSE
)
tampered_overview$canonical_n_observations[[1L]] <-
  tampered_overview$canonical_n_observations[[1L]] + 1
readr::write_csv(tampered_overview, overview_path, na = "")
test_preanalysis_expect_error(
  verify_preanalysis_comparison_artifacts(
    root = project,
    output_root = first_output_root,
    expected_normalization_manifest_sha256 = expected_normalization_sha256,
    expected_base_manifest_sha256 = expected_base_sha256
  ),
  "hash"
)

message("Testing builder rejection of an incorrect Preparation 06 hash")
wrong_hash_output_root <- tempfile("preanalysis-comparison-wrong-hash-")
dir.create(wrong_hash_output_root, recursive = TRUE)
test_preanalysis_expect_error(
  build_preanalysis_comparison_artifacts(
    root = project,
    output_root = wrong_hash_output_root,
    expected_normalization_manifest_sha256 = paste(
      rep("0", 64L),
      collapse = ""
    ),
    expected_base_manifest_sha256 = expected_base_sha256
  ),
  "hash"
)

message("Testing aggregate-only, privacy-preserving exports")
csv_paths <- unname(first_build$paths$csv)
csv_columns <- lapply(csv_paths, function(path) {
  names(readr::read_csv(
    path,
    n_max = 0L,
    show_col_types = FALSE,
    progress = FALSE
  ))
})
exported_text <- paste(
  vapply(
    c(csv_paths, first_build$paths$audit_report),
    function(path) paste(readLines(path, warn = FALSE), collapse = "\n"),
    character(1)
  ),
  collapse = "\n"
)
stopifnot(
  !any(vapply(csv_columns, function(column) "Id" %in% column, logical(1))),
  !grepl("S001", exported_text, fixed = TRUE),
  !grepl("TUM_S101", exported_text, fixed = TRUE),
  all(
    first_build$run_metadata$value[
      first_build$run_metadata$field %in%
        c(
          "participant_rows_exported",
          "participant_identifiers_exported",
          "free_text_content_exported"
        )
    ] ==
      "FALSE"
  )
)

message("All pre-analysis comparison tests passed")
