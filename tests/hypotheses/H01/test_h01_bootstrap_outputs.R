# Verify the completed H01 production bootstrap without refitting models.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H01 bootstrap-output verification requires R 4.6.1", call. = FALSE)
}

audit <- readr::read_csv(
  file.path(root, "artifacts/08_diagnostics/H01/H01_r2_bootstrap_audit.csv"),
  show_col_types = FALSE
)
failures <- readr::read_csv(
  file.path(root, "artifacts/08_diagnostics/H01/H01_r2_bootstrap_failures.csv"),
  show_col_types = FALSE
)
summaries <- readr::read_csv(
  file.path(root, "artifacts/09_tables/H01/H01_r2_bootstrap_summaries.csv"),
  show_col_types = FALSE
)
points <- readr::read_csv(
  file.path(root, "artifacts/09_tables/H01/H01_r2_point_summaries.csv"),
  show_col_types = FALSE
)
diagnostics <- readr::read_csv(
  file.path(root, "artifacts/08_diagnostics/H01/H01_model_diagnostics.csv"),
  show_col_types = FALSE
)

key <- function(data) paste(data$run_id, data$metric_id, sep = "::")
audit_keys <- key(audit)

message("Checking the 128 estimable production-bootstrap targets")
stopifnot(
  nrow(audit) == 128L,
  length(unique(audit_keys)) == 128L,
  setequal(audit_keys, unique(key(points))),
  all(audit$status == "PASS"),
  all(audit$attempted_refits == 1500L),
  all(audit$successful_refits >= 1000L),
  all(audit$used_refits == 1000L),
  all(audit$failed_refits == audit$attempted_refits - audit$successful_refits),
  nrow(failures) == sum(audit$failed_refits),
  !any(diagnostics$diagnostic_status == "FAIL_MAJOR_GATE")
)

draw_paths <- sort(list.files(
  file.path(root, "artifacts/07_models/H01"),
  pattern = "_r2_bootstrap_draws[.]rds$",
  recursive = TRUE,
  full.names = TRUE
))
stopifnot(length(draw_paths) == 128L)

measure_columns <- c(
  "marginal_r2",
  "conditional_r2",
  "participant_associated_share",
  "site_part_r2",
  "photoperiod_part_r2",
  "latitude_model_marginal_r2",
  "latitude_part_r2",
  "unrepresented_share"
)

draw_keys <- vapply(draw_paths, function(path) {
  relative <- substring(
    path,
    nchar(file.path(root, "artifacts/07_models/H01")) + 2L
  )
  parts <- strsplit(relative, "/", fixed = TRUE)[[1L]]
  stopifnot(length(parts) == 4L)
  metric_id <- sub("_r2_bootstrap_draws[.]rds$", "", parts[[4L]])
  run_id <- paste(parts[[1L]], parts[[2L]], parts[[3L]], sep = "__")
  draw <- readRDS(path)
  stopifnot(
    all(measure_columns %in% names(draw)),
    all(draw$status == "PASS"),
    identical(sort(unique(draw$bootstrap_replicate)), seq_len(1000L)),
    all(table(draw$approximation) == 1000L),
    !anyDuplicated(draw[c("approximation", "bootstrap_replicate")]),
    all(draw$attempt >= 1L & draw$attempt <= 1500L),
    all(vapply(
      draw[measure_columns],
      function(value) all(is.finite(value) | is.na(value)),
      logical(1)
    ))
  )
  paste(run_id, metric_id, sep = "::")
}, character(1))
stopifnot(setequal(draw_keys, audit_keys))

message("Checking all bootstrap 95% interval rows")
pass <- summaries$status == "PASS"
non_estimable <- summaries$status == "NON_ESTIMABLE"
stopifnot(
  nrow(summaries) == 1216L,
  sum(pass) == 1208L,
  sum(non_estimable) == 8L,
  setequal(unique(key(summaries)), audit_keys),
  all(summaries$bootstrap_successful_used == 1000L),
  all(summaries$interval_method == "joint_parametric_percentile"),
  all(is.finite(summaries$estimate[pass])),
  all(is.finite(summaries$conf_low[pass])),
  all(is.finite(summaries$conf_high[pass])),
  all(summaries$conf_low[pass] <= summaries$conf_high[pass]),
  all(is.na(summaries$estimate[non_estimable])),
  all(is.na(summaries$conf_low[non_estimable])),
  all(is.na(summaries$conf_high[non_estimable]))
)

message("Checking the completed production manifest")
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_model_results_artifacts.csv"
)
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
manifest_paths <- file.path(root, manifest$path)
draw_relative_paths <- substring(draw_paths, nchar(root) + 2L)
required_production_paths <- c(
  paste0(
    "artifacts/08_diagnostics/H01/bootstrap_production/",
    "response_family_change/",
    "H01_response_family_bootstrap_production_provenance.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H01/bootstrap_production/",
    "response_family_change/",
    "H01_response_family_bootstrap_production_runtime.csv"
  )
)
stopifnot(
  nrow(manifest) == length(unique(manifest$path)),
  all(draw_relative_paths %in% manifest$path),
  all(required_production_paths %in% manifest$path),
  all(file.exists(manifest_paths)),
  all(manifest$r_version == "4.6.1"),
  all(manifest$main_input_manifest_sha256 ==
    "ea9d47f624a8777f8416447612bfcc2309cf2bac40fdf4fd5021c8767806dfbf"),
  all(manifest$manuscript_prepared_input_manifest_sha256 ==
    "cb47b3678146604aadca875a96f79909e2d73355162683ff0603f038f3b31a25")
)
current_hashes <- vapply(
  manifest_paths,
  digest::digest,
  character(1),
  algo = "sha256",
  file = TRUE,
  serialize = FALSE
)
stopifnot(identical(unname(current_hashes), manifest$sha256))

production_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_response_family_bootstrap_production_artifacts.csv"
)
production_manifest <- readr::read_csv(
  production_manifest_path,
  show_col_types = FALSE
)
production_manifest_paths <- file.path(root, production_manifest$path)
stopifnot(
  nrow(production_manifest) == 26L,
  nrow(production_manifest) == length(unique(production_manifest$path)),
  all(file.exists(production_manifest_paths)),
  all(production_manifest$r_version == "4.6.1"),
  all(production_manifest$inference_status ==
    "PRODUCTION — 1,000 successful joint bootstrap refits")
)
production_hashes <- vapply(
  production_manifest_paths,
  digest::digest,
  character(1),
  algo = "sha256",
  file = TRUE,
  serialize = FALSE
)
stopifnot(identical(unname(production_hashes), production_manifest$sha256))

message("H01 production-bootstrap output verification passed")
