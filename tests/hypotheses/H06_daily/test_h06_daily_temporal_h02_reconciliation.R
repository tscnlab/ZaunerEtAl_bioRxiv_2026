# Focused no-refit verification of the corrected H02-aligned H06-daily
# temporal pilot, bounded basis sensitivity, and reconciliation report.

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
  "digest", "dplyr", "mgcv", "readr", "tibble", "tidyr", "melidosData"
)
stopifnot(all(vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)))
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  identical(as.character(packageVersion("mgcv")), "1.9.4"),
  identical(as.character(packageVersion("melidosData")), "1.0.6")
)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_data.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_data.R"
))

roots <- h06d_artifact_roots(root)
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
read_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = "")
}
read_h06d <- function(stage, file) {
  read_csv(file.path(root, "artifacts", stage, "H06_daily", file))
}
hash_manifest <- function(path) {
  manifest <- read_csv(path)
  manifest |>
    dplyr::mutate(
      observed_sha256 = vapply(
        file.path(root, .data$relative_path),
        .env$sha256,
        character(1)
      ),
      hash_match = .data$sha256 == .data$observed_sha256
    )
}

manifest_root <- file.path(root, "artifacts/12_manifests/H06_daily")
selected_input <- hash_manifest(file.path(
  manifest_root,
  "H06_daily_temporal_h02_input_manifest.csv"
))
selected_mismatch <- selected_input |>
  dplyr::filter(!.data$hash_match)
expected_selected_mismatch <- tibble::tribble(
  ~relative_path, ~sha256, ~observed_sha256,
  "artifacts/06_model_data/base/metrics_glasses_30_minute_context.rds",
  "afa5a23308744ae495ef07a521c99e11bd7296aa855c5cb773f71f2b68eeb8e5",
  "0ad121f104af7ae885016e4dd82f62e94e94daabd01128ed8c76407bfbc54249",
  "artifacts/12_manifests/base_model_data_artifacts.csv",
  "142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4",
  "6cfbfb18a2f6b1e31613e3fba803c3fbf64eb63e37155ae4fffd437a213b3ad0",
  "artifacts/12_manifests/metric_artifacts.csv",
  "6ec3185620d921e1f81b8464e850249613deb823988187d58794b3471303f4e8",
  "7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43",
  "audit/decisions/preparation06_current_base_model_gate.md",
  "4bc007db330b953a090985765b090d2a166515bbf056f4a56d3c44ea01426944",
  "789c1b2e0e52f1a22ed407096f0ebe1c239ee1c954197a880c19a9c32780626e"
)
stopifnot(
  nrow(selected_mismatch) == 4L,
  nrow(dplyr::anti_join(
    selected_mismatch |>
      dplyr::select(dplyr::all_of(c(
        "relative_path", "sha256", "observed_sha256"
      ))),
    expected_selected_mismatch,
    by = c("relative_path", "sha256", "observed_sha256")
  )) == 0L,
  nrow(dplyr::anti_join(
    expected_selected_mismatch,
    selected_mismatch |>
      dplyr::select(dplyr::all_of(c(
        "relative_path", "sha256", "observed_sha256"
      ))),
    by = c("relative_path", "sha256", "observed_sha256")
  )) == 0L,
  all(selected_input$hash_match[
    !selected_input$relative_path %in% expected_selected_mismatch$relative_path
  ])
)

strict_manifest_names <- c(
  "H06_daily_temporal_h02_code_manifest.csv",
  "H06_daily_temporal_h02_output_manifest.csv",
  "H06_daily_temporal_h02_basis_repair_input_manifest.csv",
  "H06_daily_temporal_h02_basis_repair_code_manifest.csv",
  "H06_daily_temporal_h02_basis_repair_output_manifest.csv",
  "H06_daily_temporal_h02_reconciliation_input_manifest.csv",
  "H06_daily_temporal_h02_reconciliation_code_manifest.csv",
  "H06_daily_temporal_h02_reconciliation_output_manifest.csv",
  "H06_daily_temporal_h02_production_gate_input_manifest.csv",
  "H06_daily_temporal_h02_production_gate_code_manifest.csv",
  "H06_daily_temporal_h02_production_gate_output_manifest.csv",
  "H06_daily_temporal_h02_upstream_repin_input_manifest.csv",
  "H06_daily_temporal_h02_upstream_repin_code_manifest.csv",
  "H06_daily_temporal_h02_upstream_repin_output_manifest.csv"
)
strict_manifests <- lapply(
  file.path(manifest_root, strict_manifest_names),
  hash_manifest
)
stopifnot(all(vapply(
  strict_manifests,
  function(manifest) all(manifest$hash_match),
  logical(1)
)))

upstream_repin_comparison <- read_h06d(
  "08_diagnostics",
  "H06_daily_temporal_h02_upstream_repin_frame_comparison.csv"
)
upstream_repin_drift <- read_h06d(
  "08_diagnostics",
  "H06_daily_temporal_h02_upstream_repin_drift_registry.csv"
)
stopifnot(
  nrow(upstream_repin_comparison) == 6L,
  all(upstream_repin_comparison$exact_row_value_and_attribute_identity),
  all(!upstream_repin_comparison$mder_read_or_used),
  all(!upstream_repin_comparison$frame_written),
  all(!upstream_repin_comparison$model_refitted),
  all(upstream_repin_comparison$qualification == "PASS"),
  nrow(upstream_repin_drift) == 5L,
  all(upstream_repin_drift$current_hash_verified),
  all(upstream_repin_drift$qualification == "PASS_NO_REFIT")
)

h02_pins <- selected_input |>
  dplyr::filter(.data$input_id %in% c(
    "h02_selected_specification",
    "h02_selected_near_eye_fit"
  ))
stopifnot(
  identical(
    h02_pins$sha256[h02_pins$input_id == "h02_selected_specification"],
    "c3c95e97dbf7a260e4aa7513a15bb8c3c7e98bdb754d97c54700e4d82629310f"
  ),
  identical(
    h02_pins$sha256[h02_pins$input_id == "h02_selected_near_eye_fit"],
    "45fa9d6b28a10a7c09d1bd4541c009977eebb8ccdbcda5f33ba306934b20acc7"
  ),
  all(h02_pins$hash_match)
)

stored_frame <- readRDS(file.path(
  roots$model_data,
  "H06_daily_temporal_h02_near_eye_frame.rds"
))
fresh_frame <- h06d_h02_temporal_frame(
  root,
  placement = "near_eye",
  diaries = h06d_load_diaries(root)
)
stopifnot(
  isTRUE(all.equal(
    stored_frame,
    fresh_frame,
    tolerance = 0,
    check.attributes = FALSE
  )),
  nrow(stored_frame) == 33057L,
  dplyr::n_distinct(stored_frame$participant_day) == 715L,
  dplyr::n_distinct(stored_frame$participant) == 137L,
  dplyr::n_distinct(stored_frame$site) == 9L,
  sum(stored_frame$arithmetic_mean_medi_lx == 0) == 10225L,
  sum(stored_frame$AR_start) == 1217L,
  all(stored_frame$elapsed_from_previous_seconds[!stored_frame$AR_start] == 0),
  identical(levels(stored_frame$work_free_day), c("Work day", "Free day")),
  identical(levels(stored_frame$activity_status), c("Sedentary", "Active"))
)

within_sleep <- stored_frame |>
  dplyr::distinct(
    .data$participant,
    .data$participant_day,
    .data$sleep_within_h
  ) |>
  dplyr::summarise(
    mean_within_h = mean(.data$sleep_within_h),
    .by = "participant"
  )
stopifnot(max(abs(within_sleep$mean_within_h)) < 1e-10)

checkpoint <- readRDS(file.path(
  roots$models,
  "H06_daily_temporal_h02_near_eye_pilot.rds"
))
fit <- checkpoint$model
expected_formula <- h06d_h02_temporal_formula("response")
stopifnot(
  inherits(fit, "bam"),
  identical(fit$family$family, "gaussian"),
  identical(fit$family$link, "identity"),
  identical(
    paste(deparse(stats::formula(fit)), collapse = " "),
    paste(deparse(expected_formula), collapse = " ")
  ),
  all(vapply(fit$smooth, function(smooth) is.null(smooth$xt), logical(1))),
  abs(checkpoint$rho - 0.5787384869) < 1e-9,
  length(checkpoint$preliminary_warnings) == 0L,
  length(checkpoint$final_warnings) == 0L,
  stats::nobs(fit) == nrow(stored_frame)
)

smooth <- read_h06d(
  "08_diagnostics",
  "H06_daily_temporal_h02_smooth_registry.csv"
)
stopifnot(
  nrow(smooth) == 8L,
  all(smooth$xt_is_null),
  identical(smooth$declared_time_margin[[1L]], "cyclic cubic"),
  all(
    smooth$declared_time_margin[2:7] == "default thin plate"
  ),
  smooth$coefficient_columns[
    smooth$term == "s(time_hour,participant)"
  ] == 1370L
)

component <- read_h06d(
  "08_diagnostics",
  "H06_daily_temporal_h02_component_diagnostics.csv"
)
site_acf <- read_h06d(
  "08_diagnostics",
  "H06_daily_temporal_h02_site_residual_acf.csv"
)
closure <- read_h06d(
  "08_diagnostics",
  "H06_daily_temporal_h02_global_closure.csv"
)
identifiability <- read_h06d(
  "08_diagnostics",
  "H06_daily_temporal_h02_identifiability_screen.csv"
)
stopifnot(
  identical(component$convergence, "full convergence"),
  component$final_warning_count == 0L,
  abs(component$smoothing_hessian_minimum_relative_eigenvalue) < 1e-12,
  component$standardized_residual_qq_correlation > 0.95,
  abs(component$final_standardized_residual_lag1) < 0.20,
  max(abs(site_acf$residual_lag1)) < 0.30,
  all(closure$cyclic_closure_pass),
  max(closure$absolute_endpoint_difference_link) < 1e-8,
  max(identifiability$fitted_term_multiple_r_squared) < 0.80
)

basis <- read_h06d(
  "08_diagnostics",
  "H06_daily_temporal_h02_basis_repair_comparison.csv"
)
basis_models <- read_h06d(
  "08_diagnostics",
  "H06_daily_temporal_h02_basis_repair_model_diagnostics.csv"
)
stopifnot(
  nrow(basis) == 1L,
  identical(
    basis$basis_repair_status,
    "K12_RETAINED_AFTER_K16_SENSITIVITY"
  ),
  isTRUE(basis$exact_same_rows),
  isTRUE(basis$curve_stability_pass),
  isTRUE(basis$global_k_check_pass),
  isTRUE(basis$diagnostic_fit_pass),
  basis$maximum_absolute_work_contrast_difference_link <= 0.05,
  basis$work_contrast_difference_rmse_link <= 0.02,
  basis$work_contrast_curve_correlation > 0.99,
  basis$selected_global_k_index > 0.90,
  basis$selected_global_k_p_value > 0.05,
  all(basis_models$convergence == "full convergence"),
  all(is.na(basis_models$warnings)),
  max(abs(basis_models$boundary_aware_lag1)) < 0.20
)

reconciled <- read_h06d(
  "08_diagnostics",
  "H06_daily_temporal_h02_reconciled_verdict.csv"
)
gate <- read_h06d(
  "08_diagnostics",
  "H06_daily_temporal_h02_production_gate_contract.csv"
)
stopifnot(
  nrow(reconciled) == 9L,
  identical(
    reconciled$assessment[
      reconciled$domain == "Overall corrected pilot gate"
    ],
    "ACCEPTABLE_FOR_EFFECT_EXTRACTION_AFTER_APPROVAL"
  ),
  sum(gate$status == "APPROVED") == 3L,
  sum(gate$status == "APPROVED_POINTWISE_ONLY") == 1L,
  sum(gate$status == "WITHHELD_PENDING_PILOT") == 1L,
  sum(gate$status == "UPSTREAM_HOLD") == 1L
)

report_manifest_path <- file.path(
  root,
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_temporal_h02_reconciliation_report_manifest.csv"
  )
)
stopifnot(file.exists(report_manifest_path))
report_manifest <- hash_manifest(report_manifest_path)
stopifnot(
  all(report_manifest$hash_match),
  identical(
    unname(file.info(file.path(root, report_manifest$relative_path))$size),
    report_manifest$size_bytes
  )
)

qmd_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/03_temporal_h02_reconciliation.qmd"
)
html_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/03_temporal_h02_reconciliation.html"
)
stopifnot(file.exists(qmd_path), file.exists(html_path))
html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("production approved with pointwise uncertainty", html,
    fixed = TRUE
  ),
  grepl("Production transition recorded", html, fixed = TRUE),
  grepl("pointwise 95% confidence intervals only", html, fixed = TRUE),
  grepl("Qualified upstream manifest change; no local repinning", html,
    fixed = TRUE
  ),
  grepl("Only its global time smooth is cyclic", html, fixed = TRUE),
  grepl(
    paste(
      "no day-type, activity, or sleep association had been extracted",
      "when this pilot verdict was made."
    ),
    html,
    fixed = TRUE
  ),
  grepl("k = 12 retained after k = 16 sensitivity", html, fixed = TRUE),
  !grepl("[ Z = _{10}(Y + 0.1 ). ]", html, fixed = TRUE),
  !grepl("Execution halted", html, fixed = TRUE),
  !grepl("Error in ", html, fixed = TRUE)
)

cat("H06-daily corrected temporal reconciliation verification: PASS\n")
