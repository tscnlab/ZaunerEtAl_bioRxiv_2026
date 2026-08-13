#!/usr/bin/env Rscript

# Extract the four approved context-association functions, pointwise 95%
# confidence intervals, and prespecified four-test BH families from only the
# production frames that passed the no-refit diagnostic gate.

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

required_packages <- c(
  "digest", "dplyr", "mgcv", "readr", "rlang", "tibble", "tidyr"
)
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  identical(as.character(utils::packageVersion("mgcv")), "1.9.4"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

sources <- c(
  "scripts/hypotheses/H06_daily/h06_daily_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_contract.R",
  paste0(
    "scripts/hypotheses/H06_daily/",
    "h06_daily_temporal_h02_production_data.R"
  ),
  paste0(
    "scripts/hypotheses/H06_daily/",
    "h06_daily_temporal_h02_production_inference.R"
  )
)
invisible(lapply(file.path(root, sources), source))

roots <- h06d_artifact_roots(root)
producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "extract_h06_daily_temporal_h02_production.R"
)
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
relative_to_root <- function(path) {
  substring(path, nchar(root) + 2L)
}
read_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = "")
}
write_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
  invisible(path)
}
verify_manifest <- function(path) {
  manifest <- read_csv(path)
  observed <- vapply(
    file.path(root, manifest$relative_path),
    sha256,
    character(1)
  )
  if (!identical(unname(observed), manifest$sha256)) {
    h06d_abort("Input manifest verification failed: %s", relative_to_root(path))
  }
  manifest
}

frame_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_frame_output_manifest.csv"
)
model_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_model_output_manifest.csv"
)
diagnostic_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_diagnostic_output_manifest.csv"
)
invisible(lapply(
  c(frame_manifest_path, model_manifest_path, diagnostic_manifest_path),
  verify_manifest
))

registry <- read_csv(file.path(
  roots$model_data,
  "H06_daily_temporal_h02_production_run_registry.csv"
)) |>
  dplyr::arrange(.data$run_order)
verdict <- read_csv(file.path(
  roots$diagnostics,
  "H06_daily_temporal_h02_production_diagnostic_verdict.csv"
))
overall <- verdict |>
  dplyr::filter(.data$domain == "Overall base-model diagnostic gate")
accepted_ids <- overall$run_id[overall$status == "ACCEPTABLE"]
not_accepted_ids <- overall$run_id[overall$status == "NOT_ACCEPTABLE"]
if (
  length(accepted_ids) != 5L ||
    !identical(
      not_accepted_ids,
      "primary__chest__paired_common"
    )
) {
  h06d_abort("Diagnostic gate differs from the reviewed five-frame contract")
}

frame_path <- function(run_id) {
  file.path(
    roots$model_data,
    paste0(
      "H06_daily_temporal_h02_production__", run_id, "__frame.rds"
    )
  )
}
model_path <- function(run_id) {
  file.path(
    roots$models,
    paste0(
      "H06_daily_temporal_h02_production__", run_id, "__model.rds"
    )
  )
}

inference_started <- proc.time()[["elapsed"]]
curve_results <- vector("list", length(accepted_ids))
test_results <- vector("list", length(accepted_ids))
runtime <- vector("list", length(accepted_ids))
for (index in seq_along(accepted_ids)) {
  run_id <- accepted_ids[[index]]
  run <- dplyr::filter(registry, .data$run_id == .env$run_id)
  message("Extracting pointwise functions for ", run_id)
  started <- proc.time()[["elapsed"]]
  frame <- readRDS(frame_path(run_id))
  checkpoint <- readRDS(model_path(run_id))
  if (
    checkpoint$run_id != run_id ||
      !identical(checkpoint$frame_sha256, sha256(frame_path(run_id))) ||
      stats::nobs(checkpoint$model) != nrow(frame)
  ) {
    h06d_abort("Selected model/frame mismatch for %s", run_id)
  }
  curve_results[[index]] <- h06d_h02_production_curves(
    checkpoint$model,
    frame,
    run
  )
  test_results[[index]] <- h06d_h02_production_smooth_tests(
    checkpoint$model,
    run
  )
  runtime[[index]] <- tibble::tibble(
    run_order = run$run_order,
    run_id = run_id,
    inference_elapsed_seconds = proc.time()[["elapsed"]] - started
  )
  rm(frame, checkpoint)
  invisible(gc())
}

functions <- dplyr::bind_rows(lapply(curve_results, `[[`, "functions")) |>
  dplyr::arrange(.data$run_order, .data$estimand_order, .data$time_hour)
profiles <- dplyr::bind_rows(lapply(curve_results, `[[`, "profiles")) |>
  dplyr::arrange(
    .data$run_order, .data$profile_family, .data$profile_order,
    .data$time_hour
  )
tests <- dplyr::bind_rows(test_results) |>
  dplyr::mutate(
    multiplicity_family_id = dplyr::case_when(
      .data$multiplicity_role == "primary_four_test_bh" ~
        "H06D-TEMP-PRIMARY-4",
      .data$multiplicity_role == "gap_four_test_bh" ~
        "H06D-TEMP-GAP-4",
      TRUE ~ NA_character_
    ),
    decision_eligible = !is.na(.data$multiplicity_family_id)
  ) |>
  dplyr::group_by(.data$multiplicity_family_id) |>
  dplyr::mutate(
    bh_adjusted_p_value = if (all(is.na(.data$multiplicity_family_id))) {
      rep(NA_real_, dplyr::n())
    } else {
      stats::p.adjust(.data$raw_p_value, method = "BH", n = 4L)
    },
    multiplicity_family_size = ifelse(
      is.na(.data$multiplicity_family_id),
      NA_integer_,
      4L
    ),
    multiplicity_rank = if (all(is.na(.data$multiplicity_family_id))) {
      rep(NA_integer_, dplyr::n())
    } else {
      rank(.data$raw_p_value, ties.method = "min")
    }
  ) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    raw_decision = dplyr::if_else(
      .data$decision_eligible,
      .data$raw_p_value < 0.05,
      NA
    ),
    bh_decision = dplyr::if_else(
      .data$decision_eligible,
      .data$bh_adjusted_p_value < 0.05,
      NA
    ),
    decision_rule = dplyr::if_else(
      .data$decision_eligible,
      "Benjamini-Hochberg across the four prespecified whole-function tests",
      "Estimation-only complementary frame; no significance screen"
    )
  ) |>
  dplyr::arrange(.data$run_order, .data$estimand_order)

function_summary <- functions |>
  dplyr::summarise(
    minimum_shifted_response_ratio = min(.data$shifted_response_ratio),
    maximum_shifted_response_ratio = max(.data$shifted_response_ratio),
    maximum_absolute_link_association = max(abs(.data$link_estimate)),
    time_of_maximum_absolute_association_h = .data$time_hour[
      which.max(abs(.data$link_estimate))
    ],
    ratio_at_maximum_absolute_association = .data$shifted_response_ratio[
      which.max(abs(.data$link_estimate))
    ],
    pointwise_bins_excluding_null = sum(
      .data$link_lower_95 > 0 | .data$link_upper_95 < 0
    ),
    evaluated_half_hour_midpoints = dplyr::n(),
    .by = c(
      "run_order", "run_id", "data_scenario_id", "data_scenario_label",
      "placement_id", "placement_label", "sample_scenario",
      "analytical_role", "multiplicity_role", "estimand_order",
      "estimand_id", "estimand_label"
    )
  ) |>
  dplyr::left_join(
    tests |>
      dplyr::select(
        run_id, estimand_id, effective_df, reference_df, test_statistic,
        raw_p_value_unclamped, raw_p_value, p_value_numerical_clamp,
        bh_adjusted_p_value, multiplicity_family_id,
        multiplicity_family_size, multiplicity_rank, raw_decision,
        bh_decision, decision_rule, approximation
      ),
    by = c("run_id", "estimand_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::arrange(.data$run_order, .data$estimand_order)

omission <- registry |>
  dplyr::filter(.data$run_id %in% not_accepted_ids) |>
  dplyr::transmute(
    run_order,
    run_id,
    data_scenario_id,
    placement_id,
    sample_scenario,
    extraction_status = "NOT_EXTRACTED",
    reason = paste(
      "Residual scale-pattern diagnostic failed:",
      "absolute-residual/fitted Spearman 0.313 exceeded the 0.300 rule;",
      "no context function or p-value was inspected"
    )
  )
runtime <- dplyr::bind_rows(runtime) |>
  dplyr::mutate(
    full_inference_wall_seconds = proc.time()[["elapsed"]] - inference_started
  )

source_paths <- c(
  functions = file.path(
    roots$source_data,
    "H06_daily_temporal_h02_production_context_functions.csv"
  ),
  profiles = file.path(
    roots$source_data,
    "H06_daily_temporal_h02_production_inverse_profiles.csv"
  )
)
table_paths <- c(
  tests = file.path(
    roots$tables,
    "H06_daily_temporal_h02_production_whole_function_tests.csv"
  ),
  summary = file.path(
    roots$tables,
    "H06_daily_temporal_h02_production_context_function_summary.csv"
  ),
  omission = file.path(
    roots$tables,
    "H06_daily_temporal_h02_production_not_extracted_frames.csv"
  )
)
diagnostic_paths <- c(
  runtime = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_inference_runtime.csv"
  )
)
invisible(Map(write_csv, list(functions, profiles), source_paths))
invisible(Map(
  write_csv,
  list(tests, function_summary, omission),
  table_paths
))
write_csv(runtime, diagnostic_paths[["runtime"]])

input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_inference_input_manifest.csv"
)
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_inference_code_manifest.csv"
)
software_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_inference_software_manifest.csv"
)
output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_inference_output_manifest.csv"
)
input_paths <- c(
  frame_manifest_path,
  model_manifest_path,
  diagnostic_manifest_path
)
write_csv(
  tibble::tibble(
    relative_path = vapply(input_paths, relative_to_root, character(1)),
    sha256 = vapply(input_paths, sha256, character(1)),
    bytes = unname(file.info(input_paths)$size),
    role = c(
      "verified_frame_bundle",
      "verified_selected_model_bundle",
      "five-of-six accepted diagnostic gate"
    )
  ),
  input_manifest_path
)
code_relative <- c(sources, producer)
write_csv(
  tibble::tibble(
    relative_path = code_relative,
    sha256 = vapply(file.path(root, code_relative), sha256, character(1)),
    bytes = unname(file.info(file.path(root, code_relative))$size)
  ),
  code_manifest_path
)
write_csv(
  tibble::tibble(
    component = c("R", required_packages),
    version = c(
      as.character(getRversion()),
      vapply(
        required_packages,
        function(package) as.character(utils::packageVersion(package)),
        character(1)
      )
    )
  ),
  software_manifest_path
)
output_paths <- c(
  unname(source_paths), unname(table_paths), unname(diagnostic_paths),
  input_manifest_path, code_manifest_path, software_manifest_path
)
write_csv(
  tibble::tibble(
    relative_path = vapply(output_paths, relative_to_root, character(1)),
    sha256 = vapply(output_paths, sha256, character(1)),
    bytes = unname(file.info(output_paths)$size),
    producer = producer,
    r_version = as.character(getRversion())
  ),
  output_manifest_path
)

message(
  "H06-D-G2P-H02 pointwise extraction complete for ",
  length(accepted_ids),
  " accepted frames; paired/common chest remained uninspected"
)
