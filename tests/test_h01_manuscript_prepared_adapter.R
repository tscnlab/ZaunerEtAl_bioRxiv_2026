options(warn = 2)

source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/metric_display_registry.R")
source("scripts/pipeline/manuscript_prepared_data.R")
source("scripts/pipeline/build_manuscript_prepared_data.R")
source("scripts/pipeline/h01_model_data.R")
source("scripts/pipeline/h01_manuscript_prepared_adapter.R")
source("scripts/pipeline/verify_h01_manuscript_prepared_data_artifacts.R")

message("Testing the manuscript-prepared H01 adapter")
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
adapted <- h01_build_manuscript_prepared_inputs(root)
stopifnot(
  nrow(adapted$contract) == 17L,
  all(adapted$contract_equivalence$implementation_fields_match),
  adapted$implementation_contract_sha256 ==
    h01_implementation_contract_sha256(adapted$main_contract),
  setequal(
    adapted$contract$metric_id[
      adapted$contract$variant_label != adapted$main_contract$variant_label
    ],
    c(
      "dose_time_sensitive_corrected_medi",
      "mder_ratio_of_integrals"
    )
  )
)

message("Testing exact adapter input grids and placement constructs")
stopifnot(
  nrow(adapted$inputs$glasses$participant_day) == 811L,
  nrow(adapted$inputs$chest$participant_day) == 897L,
  nrow(adapted$inputs$glasses$participant) == 141L,
  nrow(adapted$inputs$chest$participant) == 154L,
  nrow(adapted$inputs$glasses$metric_support) == 12447L,
  nrow(adapted$inputs$chest$metric_support) == 13763L,
  identical(
    unique(adapted$inputs$glasses$participant_day$measurement_construct),
    "hybrid_near_eye_wake_and_bedside_sleep_environment"
  ),
  identical(
    unique(adapted$inputs$chest$participant_day$measurement_construct),
    "hybrid_chest_level_wake_and_bedside_sleep_environment"
  )
)

message("Testing reversible clock conversion and exact L10 wrapping")
timing <- adapted$timing_conversion_audit
stopifnot(
  nrow(timing) == 10L,
  sum(timing$wrapped_values) == 62L,
  sum(
    timing$negative_input_values[
      timing$metric_id == "l10_midpoint" &
        timing$position == "glasses"
    ]
  ) ==
    29L,
  sum(
    timing$negative_input_values[
      timing$metric_id == "l10_midpoint" &
        timing$position == "chest"
    ]
  ) ==
    33L,
  all(
    timing$input_values_outside_0_24[
      timing$metric_id != "l10_midpoint"
    ] ==
      0L
  ),
  isTRUE(all.equal(
    h01_clock_hour_to_minute(c(-1, 0, 23.5, NA_real_)),
    c(1380, 0, 1410, NA_real_),
    tolerance = 0
  ))
)

message("Testing shared H01 row construction and exact model-frame n")
centered <- h01_build_model_rows_from_inputs(
  inputs = adapted$inputs,
  contract = adapted$contract,
  data_scenario_id = h01_manuscript_prepared_scenario_id(),
  model_implementation_id = h01_manuscript_prepared_model_implementation_id()
)
status <- h01_scenario_status(
  adapted$contract,
  data_scenario_id = h01_manuscript_prepared_scenario_id(),
  model_implementation_id = h01_manuscript_prepared_model_implementation_id()
)
flow <- h01_build_sample_flow(centered$rows, status)
h01_manuscript_prepared_verify_sample_sizes(
  flow,
  adapted$contract
)
stopifnot(
  nrow(centered$rows) == 45410L,
  all(!centered$rows$prepared_record_support_available),
  all(!centered$rows$metric_support_available),
  all(is.na(centered$rows$metric_support_valid_minutes)),
  all(is.na(centered$rows$metric_support_expected_minutes))
)

message("All manuscript-prepared H01 adapter tests passed")
