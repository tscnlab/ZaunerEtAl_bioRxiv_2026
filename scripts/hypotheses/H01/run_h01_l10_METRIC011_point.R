# Run the isolated H01 METRIC-011 L10-mean point refits.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

base::source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "The H01 METRIC-011 point refit requires R 4.6.1; found %s",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

producer <- "scripts/hypotheses/H01/run_h01_l10_METRIC011_point.R"
point_root <- file.path(
  root,
  "audit/hypotheses/H01/l10_METRIC-011/point_refit"
)
dir.create(point_root, recursive = TRUE, showWarnings = FALSE)

pin_paths <- c(
  metric_decision = "audit/decisions/l10_numerical_zero_normalization.md",
  evidence_manifest = paste0(
    "audit/reconciliation/l10_METRIC-011/",
    "METRIC-011_evidence_manifest.csv"
  ),
  main_manifest = "artifacts/12_manifests/H01_model_data_artifacts.csv",
  main_rds = "artifacts/06_model_data/H01.rds",
  gap_manifest = paste0(
    "artifacts/12_manifests/",
    "H01_manuscript_prepared_data_artifacts.csv"
  ),
  gap_rds = paste0(
    "artifacts/06_model_data/H01/scenarios/",
    "manuscript_prepared_data/H01.rds"
  )
)
pin_sha256 <- c(
  metric_decision =
    "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
  evidence_manifest =
    "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
  main_manifest =
    "25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72",
  main_rds =
    "0328fe1a698bc13965feb0b68b03ccf0fd20f32b55d6148635811b0d674e0a00",
  gap_manifest =
    "e0d98178ede61b74353e3a654e7f1b53d7e1c915833a2cda74eea45ed02f383b",
  gap_rds =
    "3c70363fc0468202a431904aa9d9444f2858af2e3add3475a56c872b49a18bd6"
)
absolute_pin_paths <- stats::setNames(
  file.path(root, unname(pin_paths)),
  names(pin_paths)
)
if (!all(file.exists(absolute_pin_paths))) {
  stop("One or more H01 METRIC-011 pinned inputs are missing", call. = FALSE)
}
observed_pin_sha256 <- vapply(
  absolute_pin_paths,
  artifact_sha256,
  character(1)
)
if (!identical(unname(observed_pin_sha256), unname(pin_sha256))) {
  stop("One or more H01 METRIC-011 input identities changed", call. = FALSE)
}

main_manifest <- readr::read_csv(
  absolute_pin_paths[["main_manifest"]],
  show_col_types = FALSE,
  progress = FALSE
)
gap_manifest <- readr::read_csv(
  absolute_pin_paths[["gap_manifest"]],
  show_col_types = FALSE,
  progress = FALSE
)
main_rds_row <- main_manifest$path == pin_paths[["main_rds"]]
gap_rds_row <- gap_manifest$path == pin_paths[["gap_rds"]]
stopifnot(
  sum(main_rds_row) == 1L,
  sum(gap_rds_row) == 1L,
  all(main_manifest$status == "PASS"),
  all(gap_manifest$status == "PASS"),
  main_manifest$sha256[main_rds_row] == pin_sha256[["main_rds"]],
  gap_manifest$sha256[gap_rds_row] == pin_sha256[["gap_rds"]]
)

metric011_input_contract <- function(project_root) {
  list(
    main = list(
      path = file.path(project_root, pin_paths[["main_rds"]]),
      manifest = file.path(project_root, pin_paths[["main_manifest"]]),
      manifest_sha256 = pin_sha256[["main_manifest"]]
    ),
    manuscript_prepared_data = list(
      path = file.path(project_root, pin_paths[["gap_rds"]]),
      manifest = file.path(project_root, pin_paths[["gap_manifest"]]),
      manifest_sha256 = pin_sha256[["gap_manifest"]]
    ),
    implementation_contract_sha256 =
      "62e5af96d08062945ad41b9031c0cfeb749fb7917db83deea2666bff98aa86de",
    shared_implementation_sha256 =
      "f0224802bd9b11900c0b446e759c8ce8495788f0fde6afd9101f76ccfabb8303",
    model_implementation_id = "new_h01_h11"
  )
}

runner_path <- file.path(
  root,
  "scripts/hypotheses/H01/run_h01_models.R"
)
contract_path <- normalizePath(
  file.path(root, "scripts/hypotheses/H01/h01_contract.R"),
  winslash = "/",
  mustWork = TRUE
)
runner_environment <- new.env(parent = globalenv())
runner_environment$source <- function(
  file,
  ...,
  local = parent.frame()
) {
  result <- base::source(file, ..., local = local)
  normalized_file <- normalizePath(
    file,
    winslash = "/",
    mustWork = TRUE
  )
  if (identical(normalized_file, contract_path)) {
    assign(
      "h01_input_contract",
      metric011_input_contract,
      envir = local
    )
  }
  invisible(result)
}

started_at <- Sys.time()
Sys.setenv(
  H01_OUTPUT_ROOT = point_root,
  H01_STAGE = "fit",
  H01_RUN_FILTER = "^main__",
  H01_METRIC_FILTER = "^l10_mean_medi$",
  H01_SAVE_PLOTS = "true"
)
sys.source(runner_path, envir = runner_environment)
finished_at <- Sys.time()

runtime <- tibble::tibble(
  status = "POINT_REFIT_COMPLETE",
  inference_status = "AUTHOR_GATE_NOT_REPORTABLE",
  metric_id = "l10_mean_medi",
  run_filter = "^main__",
  metric_filter = "^l10_mean_medi$",
  started_at = format(started_at, tz = "UTC", usetz = TRUE),
  finished_at = format(finished_at, tz = "UTC", usetz = TRUE),
  elapsed_seconds = as.numeric(
    difftime(finished_at, started_at, units = "secs")
  ),
  r_version = as.character(getRversion()),
  main_manifest_sha256 = pin_sha256[["main_manifest"]],
  main_rds_sha256 = pin_sha256[["main_rds"]],
  gap_manifest_sha256 = pin_sha256[["gap_manifest"]],
  gap_rds_sha256 = pin_sha256[["gap_rds"]],
  metric_decision_sha256 = pin_sha256[["metric_decision"]],
  evidence_manifest_sha256 = pin_sha256[["evidence_manifest"]]
)
write_csv_artifact(
  runtime,
  file.path(point_root, "H01_METRIC-011_point_refit_runtime.csv"),
  producer = producer
)

message("H01 METRIC-011 isolated point refit completed")
