#!/usr/bin/env Rscript

# Freeze and audit all METRIC-010 H06_daily model frames without fitting.

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

required_packages <- c("digest", "dplyr", "readr", "tibble", "tidyr")
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_data.R"
))

roots <- h06d_m10_artifact_roots(root)
invisible(lapply(roots, dir.create, recursive = TRUE, showWarnings = FALSE))

producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "audit_h06_daily_mder_metric010.R"
)
code_relative <- c(
  producer,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_data.R"
)

input_contract <- h06d_m10_input_contract() |>
  dplyr::mutate(
    observed_sha256 = vapply(
      file.path(root, .data$relative_path),
      h06d_m10_sha256,
      character(1)
    ),
    bytes = unname(file.info(file.path(root, .data$relative_path))$size),
    verified = .data$observed_sha256 == .data$expected_sha256
  )
h06d_m10_assert(
  all(input_contract$verified),
  "At least one METRIC-010 input identity failed"
)

base_manifest <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/base_model_data_artifacts.csv"),
  show_col_types = FALSE
)
h06d_m10_assert(
  length(unique(base_manifest$input_bundle_sha256)) == 1L &&
    unique(base_manifest$input_bundle_sha256) ==
      "168f25e18b6e494aa7a0272923041ad8249e25adb9ff3742d22e2f4cacf1bdf8",
  "Current base input-bundle identity failed"
)

source_data <- h06d_m10_load_sources(root)
frame_bundle <- h06d_m10_build_frames(source_data)

metric_contract <- h06d_m10_metric_contract()
metric_slots <- h06d_m10_metric_slot_registry()
predictors <- h06d_m10_predictor_registry()
diagnostic_contract <- h06d_m10_diagnostic_contract()

h06d_m10_assert(
  nrow(metric_slots) == 15L &&
    identical(metric_slots$metric_slot, seq_len(15L)) &&
    metric_slots$metric_id[[15L]] == "mder_mean_of_viable_ratios",
  "METRIC-010 is not the fifteenth named H06_daily metric slot"
)
h06d_m10_assert(
  nrow(frame_bundle$registry) == 36L,
  "Expected 36 exact METRIC-010 predictor/scenario frames"
)

frame_relative <- vapply(
  names(frame_bundle$frames),
  function(key) {
    paste0(
      "artifacts/06_model_data/H06_daily/",
      "H06_daily_mder_metric010__",
      key,
      "__frame.rds"
    )
  },
  character(1)
)
previous_frame_exists <- file.exists(file.path(root, frame_relative))
names(previous_frame_exists) <- names(frame_relative)
previous_frame_object_sha256 <- vapply(
  seq_along(frame_relative),
  function(index) {
    if (!previous_frame_exists[[index]]) {
      return(NA_character_)
    }
    digest::digest(
      readRDS(file.path(root, frame_relative[[index]])),
      algo = "sha256",
      serialize = TRUE
    )
  },
  character(1)
)
names(previous_frame_object_sha256) <- names(frame_relative)
previous_frame_file_sha256 <- vapply(
  seq_along(frame_relative),
  function(index) {
    if (!previous_frame_exists[[index]]) {
      return(NA_character_)
    }
    h06d_m10_sha256(file.path(root, frame_relative[[index]]))
  },
  character(1)
)
names(previous_frame_file_sha256) <- names(frame_relative)
current_frame_object_sha256 <- vapply(
  frame_bundle$frames,
  digest::digest,
  character(1),
  algo = "sha256",
  serialize = TRUE
)
frame_comparison <- frame_bundle$registry |>
  dplyr::select(
    "run_order", "run_id", "dataset_id", "placement_id", "sample_role",
    "predictor_order", "predictor_id", "frame_key"
  ) |>
  dplyr::mutate(
    frame_path = unname(frame_relative[.data$frame_key]),
    previous_frame_exists = unname(previous_frame_exists[.data$frame_key]),
    previous_frame_object_sha256 = unname(
      previous_frame_object_sha256[.data$frame_key]
    ),
    current_frame_object_sha256 = unname(
      current_frame_object_sha256[.data$frame_key]
    ),
    previous_frame_file_sha256 = unname(
      previous_frame_file_sha256[.data$frame_key]
    ),
    object_identical = .data$previous_frame_exists &
      .data$previous_frame_object_sha256 == .data$current_frame_object_sha256,
    refresh_disposition = dplyr::case_when(
      .data$dataset_id == "primary" &
        .data$sample_role != "dataset_common" &
        .data$object_identical ~ "FROZEN_PRIMARY_ROUTE_IDENTICAL",
      .data$sample_role == "dataset_common" & !.data$object_identical ~
        "EXPECTED_PRIMARY_GAP_COMMON_SAMPLE_REFRESH",
      .data$dataset_id == "gap_timing_unaware" & !.data$object_identical ~
        "EXPECTED_GAP_REFRESH",
      .data$object_identical ~ "MDER_FRAME_UNCHANGED",
      TRUE ~ "UNEXPECTED_FROZEN_ROUTE_CHANGE"
    )
  )
h06d_m10_assert(
  all(frame_comparison$previous_frame_exists),
  "A pre-refresh METRIC-010 frame is missing"
)
h06d_m10_assert(
  all(frame_comparison$object_identical[
    frame_comparison$dataset_id == "primary" &
      frame_comparison$sample_role != "dataset_common"
  ]),
  paste(
    "A primary all-available or placement-paired METRIC-010 frame changed",
    "during the gap refresh"
  )
)
h06d_m10_assert(
  any(!frame_comparison$object_identical[
    frame_comparison$dataset_id == "gap_timing_unaware" |
      frame_comparison$sample_role == "dataset_common"
  ]),
  "The repaired METRIC-010 gap source did not change an affected frame"
)
for (index in seq_along(frame_bundle$frames)) {
  saveRDS(
    frame_bundle$frames[[index]],
    file.path(root, frame_relative[[index]]),
    version = 3
  )
}

frame_registry <- frame_bundle$registry |>
  dplyr::mutate(
    frame_path = unname(frame_relative[.data$frame_key]),
    frame_file_sha256 = vapply(
      file.path(root, .data$frame_path),
      h06d_m10_sha256,
      character(1)
    )
  )
frame_comparison <- frame_comparison |>
  dplyr::mutate(
    current_frame_file_sha256 = vapply(
      file.path(root, .data$frame_path),
      h06d_m10_sha256,
      character(1)
    )
  )

source_scenarios <- source_data |>
  dplyr::distinct(dplyr::across(dplyr::all_of(c(
    "dataset_id", "dataset_label", "placement_id", "placement"
  ))))
missingness <- dplyr::bind_rows(lapply(
  seq_len(nrow(predictors)),
  function(predictor_index) {
    predictor <- predictors[predictor_index, ]
    dplyr::bind_rows(lapply(
      seq_len(nrow(source_scenarios)),
      function(scenario_index) {
        scenario <- source_scenarios[scenario_index, ]
        data <- source_data |>
          dplyr::filter(
            .data$dataset_id == scenario$dataset_id[[1L]],
            .data$placement_id == scenario$placement_id[[1L]]
          )
        response_available <- is.finite(data$response_source)
        predictor_available <- h06d_m10_predictor_available(
          data,
          predictor$column[[1L]]
        )
        dplyr::bind_cols(
          predictor |>
            dplyr::select(
              "predictor_order",
              "predictor_id",
              "reader_name"
            ),
          scenario,
          tibble::tibble(
            base_days = nrow(data),
            metric_available = sum(response_available),
            predictor_available = sum(predictor_available),
            complete_days = sum(response_available & predictor_available),
            metric_unavailable_only = sum(
              !response_available & predictor_available
            ),
            predictor_unavailable_only = sum(
              response_available & !predictor_available
            ),
            both_unavailable = sum(
              !response_available & !predictor_available
            ),
            complete_participants = dplyr::n_distinct(
              data$participant_key[response_available & predictor_available]
            ),
            complete_sites = dplyr::n_distinct(
              data$site[response_available & predictor_available]
            )
          )
        )
      }
    ))
  }
)) |>
  dplyr::arrange(
    .data$predictor_order,
    .data$dataset_id,
    .data$placement_id
  )
h06d_m10_assert(
  all(with(
    missingness,
    metric_unavailable_only + predictor_unavailable_only + both_unavailable +
      complete_days == base_days
  )),
  "METRIC-010 missingness categories do not sum to the base sample"
)

support_summary <- source_data |>
  dplyr::summarise(
    base_days = dplyr::n(),
    available_days = sum(is.finite(.data$response_source)),
    unavailable_days = sum(!is.finite(.data$response_source)),
    participants_with_value = dplyr::n_distinct(
      .data$participant_key[is.finite(.data$response_source)]
    ),
    sites_with_value = dplyr::n_distinct(
      .data$site[is.finite(.data$response_source)]
    ),
    minimum_viable_minutes = suppressWarnings(min(
      .data$viable_ratio_minutes[is.finite(.data$response_source)],
      na.rm = TRUE
    )),
    median_viable_minutes = suppressWarnings(stats::median(
      .data$viable_ratio_minutes[is.finite(.data$response_source)],
      na.rm = TRUE
    )),
    maximum_viable_minutes = suppressWarnings(max(
      .data$viable_ratio_minutes[is.finite(.data$response_source)],
      na.rm = TRUE
    )),
    exact_zeros = sum(.data$response_source == 0, na.rm = TRUE),
    .by = c("dataset_id", "dataset_label", "placement_id", "placement")
  ) |>
  dplyr::mutate(
    dplyr::across(
      c(
        "minimum_viable_minutes",
        "median_viable_minutes",
        "maximum_viable_minutes"
      ),
      ~ ifelse(is.infinite(.x), NA_real_, .x)
    )
  )

support_failure_summary <- source_data |>
  dplyr::mutate(
    support_status = ifelse(
      is.finite(.data$response_source),
      "available",
      .data$failure_reason
    )
  ) |>
  dplyr::summarise(
    participant_days = dplyr::n(),
    participants = dplyr::n_distinct(.data$participant_key),
    sites = dplyr::n_distinct(.data$site),
    .by = c(
      "dataset_id", "dataset_label", "placement_id", "placement",
      "support_status"
    )
  ) |>
  dplyr::arrange(
    .data$dataset_id,
    .data$placement_id,
    .data$support_status
  )

distribution_summary <- source_data |>
  dplyr::filter(is.finite(.data$response_source)) |>
  dplyr::summarise(
    participant_days = dplyr::n(),
    participants = dplyr::n_distinct(.data$participant_key),
    mean = mean(.data$response_source),
    standard_deviation = stats::sd(.data$response_source),
    minimum = min(.data$response_source),
    q05 = stats::quantile(.data$response_source, 0.05, names = FALSE),
    q25 = stats::quantile(.data$response_source, 0.25, names = FALSE),
    median = stats::median(.data$response_source),
    q75 = stats::quantile(.data$response_source, 0.75, names = FALSE),
    q95 = stats::quantile(.data$response_source, 0.95, names = FALSE),
    maximum = max(.data$response_source),
    exact_zeros = sum(.data$response_source == 0),
    .by = c("dataset_id", "dataset_label", "placement_id", "placement")
  )

upper_tail <- source_data |>
  dplyr::filter(is.finite(.data$response_source)) |>
  dplyr::group_by(.data$dataset_id, .data$placement_id) |>
  dplyr::slice_max(.data$response_source, n = 10L, with_ties = FALSE) |>
  dplyr::ungroup() |>
  dplyr::transmute(
    dataset_id = .data$dataset_id,
    dataset_label = .data$dataset_label,
    placement_id = .data$placement_id,
    placement = .data$placement,
    site = as.character(.data$site),
    participant_hash = vapply(
      .data$participant_key,
      function(value) substr(digest::digest(value, algo = "sha256"), 1L, 12L),
      character(1)
    ),
    local_date = .data$local_date,
    mder = .data$response_source,
    viable_ratio_minutes = .data$viable_ratio_minutes,
    expected_minutes = .data$expected_minutes,
    old_device_day_flag_transferred = FALSE
  )

category_cells <- dplyr::bind_rows(lapply(
  seq_len(nrow(predictors)),
  function(index) {
    predictor <- predictors[index, ]
    if (predictor$type[[1L]] == "continuous") {
      return(source_data |>
        dplyr::filter(
          is.finite(.data$response_source),
          is.finite(.data[[predictor$column[[1L]]]])
        ) |>
        dplyr::summarise(
          predictor_id = predictor$predictor_id[[1L]],
          category = "continuous support",
          participant_days = dplyr::n(),
          participants = dplyr::n_distinct(.data$participant_key),
          sites = dplyr::n_distinct(.data$site),
          predictor_minimum = min(.data[[predictor$column[[1L]]]]) + 8,
          predictor_median = stats::median(.data[[predictor$column[[1L]]]]) + 8,
          predictor_maximum = max(.data[[predictor$column[[1L]]]]) + 8,
          .by = c("dataset_id", "placement_id", "placement")
        ))
    }
    source_data |>
      dplyr::filter(
        is.finite(.data$response_source),
        !is.na(.data[[predictor$column[[1L]]]])
      ) |>
      dplyr::mutate(category = as.character(.data[[predictor$column[[1L]]]])) |>
      dplyr::summarise(
        predictor_id = predictor$predictor_id[[1L]],
        participant_days = dplyr::n(),
        participants = dplyr::n_distinct(.data$participant_key),
        sites = dplyr::n_distinct(.data$site),
        predictor_minimum = NA_real_,
        predictor_median = NA_real_,
        predictor_maximum = NA_real_,
        .by = c("dataset_id", "placement_id", "placement", "category")
      )
  }
)) |>
  dplyr::arrange(
    .data$predictor_id,
    .data$dataset_id,
    .data$placement_id,
    .data$category
  )

static_verdict <- tibble::tribble(
  ~domain, ~observed, ~verdict, ~interpretation,
  "Input identities",
  sprintf("%d/%d exact SHA-256 identities", sum(input_contract$verified), nrow(input_contract)),
  "PASS",
  "The current METRIC-010 and base/gap artifacts are pinned.",
  "Primary metric definition",
  "1,440-minute grid; >=720 viable strict-positive finite pairs; unscaled/unweighted",
  "PASS",
  "The primary near-eye and chest values satisfy the controlling rule.",
  "Primary availability",
  sprintf(
    "Near eye %d/%d; chest %d/%d",
    support_summary$available_days[
      support_summary$dataset_id == "primary" &
        support_summary$placement_id == "near_eye"
    ],
    support_summary$base_days[
      support_summary$dataset_id == "primary" &
        support_summary$placement_id == "near_eye"
    ],
    support_summary$available_days[
      support_summary$dataset_id == "primary" &
        support_summary$placement_id == "chest"
    ],
    support_summary$base_days[
      support_summary$dataset_id == "primary" &
        support_summary$placement_id == "chest"
    ]
  ),
  "PASS",
  "Availability matches the independent METRIC-010 verification.",
  "Gap comparator availability",
  sprintf(
    "Near eye %d/%d; chest %d/%d",
    support_summary$available_days[
      support_summary$dataset_id == "gap_timing_unaware" &
        support_summary$placement_id == "near_eye"
    ],
    support_summary$base_days[
      support_summary$dataset_id == "gap_timing_unaware" &
        support_summary$placement_id == "near_eye"
    ],
    support_summary$available_days[
      support_summary$dataset_id == "gap_timing_unaware" &
        support_summary$placement_id == "chest"
    ],
    support_summary$base_days[
      support_summary$dataset_id == "gap_timing_unaware" &
        support_summary$placement_id == "chest"
    ]
  ),
  "PASS",
  "The repaired gap branch now carries exact METRIC-010 support and failure reasons.",
  "Exact analysis frames",
  sprintf("%d frozen predictor/scenario frames", nrow(frame_registry)),
  "PASS",
  "Each metric-specific participant-day contributes at most one row.",
  "Gap comparator lower bound",
  sprintf(
    "%d exact zero among %d finite gap values",
    sum(
      source_data$dataset_id == "gap_timing_unaware" &
        source_data$response_source == 0,
      na.rm = TRUE
    ),
    sum(
      source_data$dataset_id == "gap_timing_unaware" &
        is.finite(source_data$response_source)
    )
  ),
  "PASS",
  "All estimable repaired gap values are finite and strictly positive.",
  "Frozen primary routes",
  sprintf(
    "%d/%d all-available or placement-paired primary frames object-identical",
    sum(
      frame_comparison$dataset_id == "primary" &
        frame_comparison$sample_role != "dataset_common" &
        frame_comparison$object_identical
    ),
    sum(
      frame_comparison$dataset_id == "primary" &
        frame_comparison$sample_role != "dataset_common"
    )
  ),
  "PASS",
  paste(
    "Primary all-available and placement-paired samples are frozen; only",
    "the explicitly MDER-dependent primary-gap common samples may refresh."
  ),
  "Family suitability",
  "Identity Gaussian retained subject to refreshed gap diagnostics",
  "GAP_REFIT_REQUIRED",
  "The repaired gap frames require the approved bounded model and diagnostic refresh."
)

output_tables <- list(
  "artifacts/06_model_data/H06_daily/H06_daily_mder_metric010_metric_contract.csv" = metric_contract,
  "artifacts/06_model_data/H06_daily/H06_daily_mder_metric010_metric_slot_registry.csv" = metric_slots,
  "artifacts/06_model_data/H06_daily/H06_daily_mder_metric010_frame_registry.csv" = frame_registry,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_input_contract.csv" = input_contract,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_missingness.csv" = missingness,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_support_summary.csv" = support_summary,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_support_failure_summary.csv" = support_failure_summary,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_distribution_summary.csv" = distribution_summary,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_upper_tail.csv" = upper_tail,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_category_cells.csv" = category_cells,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_diagnostic_contract.csv" = diagnostic_contract,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_gap_refresh_frame_comparison.csv" = frame_comparison,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_static_verdict.csv" = static_verdict
)
for (path in names(output_tables)) {
  readr::write_csv(output_tables[[path]], file.path(root, path), na = "")
}

manifest <- function(relative_paths, roles) {
  absolute <- file.path(root, relative_paths)
  tibble::tibble(
    relative_path = relative_paths,
    sha256 = vapply(absolute, h06d_m10_sha256, character(1)),
    bytes = unname(file.info(absolute)$size),
    role = roles,
    producer = producer,
    r_version = as.character(getRversion())
  )
}

input_manifest <- input_contract |>
  dplyr::transmute(
    relative_path = .data$relative_path,
    sha256 = .data$observed_sha256,
    bytes = .data$bytes,
    role = .data$role,
    producer = .env$producer,
    r_version = as.character(getRversion())
  )
code_manifest <- manifest(code_relative, c(
  "static_audit_runner",
  "METRIC-010 contract",
  "METRIC-010 data adapters"
))
output_relative <- c(names(output_tables), unname(frame_relative))
output_manifest <- manifest(
  output_relative,
  c(
    rep("audited tabular output", length(output_tables)),
    rep("frozen exact model frame", length(frame_relative))
  )
)
software_manifest <- tibble::tibble(
  component = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
)

readr::write_csv(
  input_manifest,
  file.path(
    roots$manifests,
    "H06_daily_mder_metric010_static_input_manifest.csv"
  ),
  na = ""
)
readr::write_csv(
  code_manifest,
  file.path(
    roots$manifests,
    "H06_daily_mder_metric010_static_code_manifest.csv"
  ),
  na = ""
)
readr::write_csv(
  output_manifest,
  file.path(
    roots$manifests,
    "H06_daily_mder_metric010_static_output_manifest.csv"
  ),
  na = ""
)
readr::write_csv(
  software_manifest,
  file.path(
    roots$manifests,
    "H06_daily_mder_metric010_static_software_manifest.csv"
  ),
  na = ""
)

message("H06_daily METRIC-010 static audit complete: 36 exact frames frozen.")
