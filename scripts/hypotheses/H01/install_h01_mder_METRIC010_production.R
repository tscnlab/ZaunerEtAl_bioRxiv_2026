# Install the sealed H01 METRIC-010 production-integration candidate.
#
# This script performs no fitting, prediction, resampling, or other scientific
# calculation. It atomically promotes the already verified MDER candidate,
# archives the superseded ratio-of-integrals bundle, and reseals the current
# H01 model-results manifest.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H01 METRIC-010 installation requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

approval <- Sys.getenv("H01_MDER_INTEGRATION_APPROVAL", unset = "")
if (!identical(approval, "approved_2026-08-31")) {
  stop("Missing exact H01 METRIC-010 integration approval token", call. = FALSE)
}

producer <- paste0(
  "scripts/hypotheses/H01/",
  "install_h01_mder_METRIC010_production.R"
)
old_metric_id <- "mder_ratio_of_integrals"
metric_id <- "mder_mean_of_viable_ratios"
integration_root <- file.path(
  root,
  "audit/hypotheses/H01/mder_METRIC-010/production_integration"
)
candidate_root <- file.path(integration_root, "candidate")
candidate_manifest_path <- file.path(
  integration_root,
  "H01_METRIC-010_integration_candidate_manifest.csv"
)
non_mder_baseline_path <- file.path(
  integration_root,
  "H01_METRIC-010_non_mder_preintegration_baseline.csv"
)
support_path <- file.path(
  integration_root,
  "H01_METRIC-010_support_disposition.csv"
)
model_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_model_results_artifacts.csv"
)
archive_root <- file.path(
  integration_root,
  "superseded_ratio_of_integrals_canonical"
)

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
    stop("Missing H01 METRIC-010 installation input: ", path, call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

hash_pin <- function(path, expected) {
  if (!file.exists(path)) {
    stop("Missing pinned installation input: ", path, call. = FALSE)
  }
  observed <- artifact_sha256(path)
  if (!identical(observed, expected)) {
    stop(
      "Pinned installation input drift: ", relative_to_root(path),
      " expected ", expected, " observed ", observed,
      call. = FALSE
    )
  }
  invisible(path)
}

copy_atomic <- function(from, to) {
  if (!file.exists(from)) {
    stop("Missing sealed candidate artifact: ", from, call. = FALSE)
  }
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(to), "."),
    tmpdir = dirname(to)
  )
  on.exit(unlink(temporary), add = TRUE)
  if (!file.copy(from, temporary, overwrite = TRUE, copy.mode = TRUE)) {
    stop("Could not stage sealed candidate artifact: ", from, call. = FALSE)
  }
  atomic_replace_artifact(temporary, to)
}

pin_table <- tibble::tribble(
  ~path, ~sha256,
  "scripts/hypotheses/H01/integrate_h01_mder_METRIC010_production.R",
  "7b51b474c6586ef5c49955e00d4d900a758848c8d77b99806eb588acd5b23967",
  paste0(
    "audit/hypotheses/H01/mder_METRIC-010/production_integration/",
    "H01_METRIC-010_integration_candidate_manifest.csv"
  ),
  "41298ccc92490ea7930ab8f2d630debef131fb05ba5464db888b6a441167e4f2",
  paste0(
    "audit/hypotheses/H01/mder_METRIC-010/production_integration/",
    "H01_METRIC-010_non_mder_preintegration_baseline.csv"
  ),
  "529830e08beab82ac498055f5cdc8b388fb2826f04fa6e3cf1748a26fbd28c72",
  paste0(
    "audit/hypotheses/H01/mder_METRIC-010/production_integration/",
    "H01_METRIC-010_support_disposition.csv"
  ),
  "0b29769ca9a1ec68bf5c5eab2d7a744ec73c1474bf650859abfbf75d88357549",
  "artifacts/12_manifests/H01_model_results_artifacts.csv",
  "eceb971726ee4a52cf4266ad1a44441c45078328c08f32c1ef1c1e83df2aee7c"
)
invisible(mapply(
  function(path, sha256) hash_pin(file.path(root, path), sha256),
  pin_table$path,
  pin_table$sha256,
  SIMPLIFY = FALSE
))

# Re-run the non-mutating production verifier before installation.
source(file.path(root, "tests/hypotheses/H01/test_h01_mder_METRIC010_production.R"))

candidate_manifest <- read_csv_strict(candidate_manifest_path)
stopifnot(
  nrow(candidate_manifest) == 66L,
  !anyDuplicated(candidate_manifest$path),
  all(candidate_manifest$r_version == "4.6.1")
)
candidate_files <- file.path(candidate_root, candidate_manifest$path)
stopifnot(
  all(file.exists(candidate_files)),
  identical(
    unname(vapply(candidate_files, artifact_sha256, character(1))),
    unname(candidate_manifest$sha256)
  ),
  identical(
    as.numeric(file.info(candidate_files)$size),
    as.numeric(candidate_manifest$bytes)
  )
)

non_mder_baseline <- read_csv_strict(non_mder_baseline_path)
non_mder_files <- file.path(root, non_mder_baseline$path)
stopifnot(
  nrow(non_mder_baseline) == 1017L,
  all(file.exists(non_mder_files)),
  identical(
    unname(vapply(non_mder_files, artifact_sha256, character(1))),
    unname(non_mder_baseline$sha256)
  )
)

model_manifest <- read_csv_strict(model_manifest_path)
manifest_files <- file.path(root, model_manifest$path)
stopifnot(
  nrow(model_manifest) == 1112L,
  !anyDuplicated(model_manifest$path),
  all(file.exists(manifest_files))
)
observed_manifest_hashes <- unname(vapply(
  manifest_files,
  artifact_sha256,
  character(1)
))
preexisting_drift <- c(
  "artifacts/09_tables/H01/reporting/H01_reporting_model_overview.csv",
  "artifacts/09_tables/H01/reporting/H01_reporting_r2_preview_long.csv",
  "artifacts/09_tables/H01/reporting/H01_reporting_r2_preview_wide.csv",
  "artifacts/09_tables/H01/reporting/H01_reporting_site_followups.csv",
  "artifacts/09_tables/H01/reporting/H01_reporting_v0_new_r2.csv",
  "artifacts/09_tables/H01/reporting/H01_reporting_v0_new_tests.csv",
  "scripts/hypotheses/H01/h01_contract.R"
)
mismatch <- observed_manifest_hashes != model_manifest$sha256
stopifnot(
  setequal(model_manifest$path[mismatch], preexisting_drift),
  all(!candidate_manifest$path %in% preexisting_drift)
)

old_rows <- grepl(old_metric_id, model_manifest$path, fixed = TRUE)
old_paths <- model_manifest$path[old_rows]
old_files <- file.path(root, old_paths)
stopifnot(
  sum(old_rows) == 49L,
  all(file.exists(old_files)),
  !any(grepl(metric_id, model_manifest$path, fixed = TRUE))
)

# Copy and verify the complete superseded canonical bundle before removing any
# active-tree file. The archived hierarchy retains each original path.
archive_files <- file.path(archive_root, old_paths)
for (index in seq_along(old_files)) {
  dir.create(dirname(archive_files[[index]]), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(archive_files[[index]])) {
    if (!identical(
      artifact_sha256(archive_files[[index]]),
      artifact_sha256(old_files[[index]])
    )) {
      stop("Existing superseded archive differs: ", old_paths[[index]], call. = FALSE)
    }
  } else if (!file.copy(
    old_files[[index]],
    archive_files[[index]],
    overwrite = FALSE,
    copy.mode = TRUE
  )) {
    stop("Could not archive superseded artifact: ", old_paths[[index]], call. = FALSE)
  }
}
stopifnot(identical(
  unname(vapply(archive_files, artifact_sha256, character(1))),
  unname(vapply(old_files, artifact_sha256, character(1)))
))
archive_manifest <- tibble::tibble(
  original_path = old_paths,
  archive_path = relative_to_root(archive_files),
  sha256 = unname(vapply(archive_files, artifact_sha256, character(1))),
  bytes = as.numeric(file.info(archive_files)$size),
  disposition = "SUPERSEDED_BY_METRIC-010_MEAN_OF_VIABLE_RATIOS",
  producer = producer,
  r_version = as.character(getRversion())
)
archive_manifest_path <- file.path(
  integration_root,
  "H01_METRIC-010_superseded_ratio_of_integrals_archive.csv"
)
write_csv_artifact(archive_manifest, archive_manifest_path, producer = producer)

canonical_candidate_files <- file.path(root, candidate_manifest$path)
candidate_existed_before <- file.exists(canonical_candidate_files)
pre_state <- tibble::tibble(
  path = candidate_manifest$path,
  existed_before = candidate_existed_before,
  sha256_before = ifelse(
    candidate_existed_before,
    unname(vapply(canonical_candidate_files, function(path) {
      if (file.exists(path)) artifact_sha256(path) else NA_character_
    }, character(1))),
    NA_character_
  ),
  bytes_before = ifelse(
    candidate_existed_before,
    as.numeric(file.info(canonical_candidate_files)$size),
    NA_real_
  )
)

# Promote exactly the 66 sealed candidate files.
for (index in seq_along(candidate_files)) {
  copy_atomic(candidate_files[[index]], canonical_candidate_files[[index]])
}
stopifnot(
  all(file.exists(canonical_candidate_files)),
  identical(
    unname(vapply(canonical_candidate_files, artifact_sha256, character(1))),
    unname(candidate_manifest$sha256)
  )
)

# Remove the superseded active-tree copies only after their verified archive
# and all replacement candidates are present. Every removal is recoverable
# from the archive recorded above.
removed <- file.remove(old_files)
if (!all(removed) || any(file.exists(old_files))) {
  stop("Could not retire every superseded MDER artifact", call. = FALSE)
}

# Replace the 49 superseded rows with 48 current MDER rows. All aggregate rows
# are resealed to their installed candidate identities. The seven accepted
# pre-existing current H01 source/reporting identities are also reconciled.
updated_manifest <- model_manifest[!old_rows, , drop = FALSE]
existing_index <- match(candidate_manifest$path, updated_manifest$path)
existing_candidate <- !is.na(existing_index)
updated_manifest$sha256[existing_index[existing_candidate]] <-
  candidate_manifest$sha256[existing_candidate]
updated_manifest$bytes[existing_index[existing_candidate]] <-
  candidate_manifest$bytes[existing_candidate]
updated_manifest$producer[existing_index[existing_candidate]] <- producer

new_candidate <- !existing_candidate
stopifnot(sum(new_candidate) == 48L)
metadata <- model_manifest[1L, , drop = FALSE]
new_rows <- tibble::tibble(
  path = candidate_manifest$path[new_candidate],
  artifact_type = tolower(tools::file_ext(candidate_manifest$path[new_candidate])),
  sha256 = candidate_manifest$sha256[new_candidate],
  bytes = as.numeric(candidate_manifest$bytes[new_candidate]),
  producer = producer,
  r_version = as.character(getRversion()),
  main_input_manifest_sha256 = metadata$main_input_manifest_sha256,
  manuscript_prepared_input_manifest_sha256 =
    metadata$manuscript_prepared_input_manifest_sha256,
  model_implementation_id = metadata$model_implementation_id
)
updated_manifest <- bind_rows(updated_manifest, new_rows) |>
  arrange(.data$path)
updated_files <- file.path(root, updated_manifest$path)
stopifnot(
  nrow(updated_manifest) == 1111L,
  !anyDuplicated(updated_manifest$path),
  all(file.exists(updated_files)),
  all(updated_manifest$r_version == "4.6.1"),
  all(updated_manifest$main_input_manifest_sha256 ==
    "ea9d47f624a8777f8416447612bfcc2309cf2bac40fdf4fd5021c8767806dfbf"),
  all(updated_manifest$manuscript_prepared_input_manifest_sha256 ==
    "cb47b3678146604aadca875a96f79909e2d73355162683ff0603f038f3b31a25")
)
updated_manifest$sha256 <- unname(vapply(
  updated_files,
  artifact_sha256,
  character(1)
))
updated_manifest$bytes <- as.numeric(file.info(updated_files)$size)
write_csv_artifact(updated_manifest, model_manifest_path, producer = producer)

sealed_manifest <- read_csv_strict(model_manifest_path)
sealed_files <- file.path(root, sealed_manifest$path)
stopifnot(
  nrow(sealed_manifest) == 1111L,
  identical(
    unname(vapply(sealed_files, artifact_sha256, character(1))),
    unname(sealed_manifest$sha256)
  )
)

post_state <- pre_state |>
  mutate(
    sha256_after = unname(vapply(
      file.path(root, .data$path),
      artifact_sha256,
      character(1)
    )),
    bytes_after = as.numeric(file.info(file.path(root, .data$path))$size),
    changed = is.na(.data$sha256_before) |
      .data$sha256_before != .data$sha256_after
  )
transition_path <- file.path(
  integration_root,
  "H01_METRIC-010_canonical_artifact_transition.csv"
)
write_csv_artifact(post_state, transition_path, producer = producer)

non_mder_after <- unname(vapply(
  non_mder_files,
  artifact_sha256,
  character(1)
))
stopifnot(identical(non_mder_after, unname(non_mder_baseline$sha256)))

production_audit <- read_csv_strict(file.path(
  root,
  paste0(
    "audit/hypotheses/H01/mder_METRIC-010/bootstrap_production/",
    "diagnostics/H01_METRIC-010_bootstrap_production_audit.csv"
  )
))
production_runtime <- read_csv_strict(file.path(
  root,
  paste0(
    "audit/hypotheses/H01/mder_METRIC-010/bootstrap_production/",
    "diagnostics/H01_METRIC-010_bootstrap_production_runtime.csv"
  )
))
support <- read_csv_strict(support_path)
summary <- tibble::tibble(
  metric_decision = "METRIC-010",
  targets = nrow(production_audit),
  successful_refits_per_target = min(production_audit$used_refits),
  total_used_refits = sum(production_audit$used_refits),
  total_attempted_refits = sum(production_audit$attempted_refits),
  total_successful_refits = sum(production_audit$successful_refits),
  total_failed_refits = sum(production_audit$failed_refits),
  total_warning_refits = sum(production_audit$warning_refits),
  target_wall_seconds = sum(production_runtime$wall_seconds),
  support_disposition_changes = sum(
    support$disposition_changed,
    na.rm = TRUE
  ),
  archived_superseded_artifacts = nrow(archive_manifest),
  installed_candidate_artifacts = nrow(candidate_manifest),
  focused_verifier = "PASS",
  integration_status = "PASS_NO_NEW_AUTHOR_GATE"
)
summary_path <- file.path(
  integration_root,
  "H01_METRIC-010_production_integration_summary.csv"
)
write_csv_artifact(summary, summary_path, producer = producer)

integration_inputs <- file.path(root, pin_table$path)
integration_outputs <- c(
  canonical_candidate_files,
  model_manifest_path,
  archive_manifest_path,
  transition_path,
  summary_path
)
integration_manifest <- bind_rows(lapply(
  sort(unique(c(integration_inputs, integration_outputs))),
  function(path) {
    tibble::tibble(
      path = relative_to_root(path),
      sha256 = artifact_sha256(path),
      bytes = as.numeric(file.info(path)$size),
      role = ifelse(
        path %in% integration_outputs,
        "H01 METRIC-010 integrated output",
        "H01 METRIC-010 verified input"
      ),
      producer = producer,
      r_version = as.character(getRversion()),
      integration_status = "PASS_NO_NEW_AUTHOR_GATE"
    )
  }
))
integration_manifest_path <- file.path(
  integration_root,
  "H01_METRIC-010_production_integration_manifest.csv"
)
write_csv_artifact(
  integration_manifest,
  integration_manifest_path,
  producer = producer
)

message(
  "H01 METRIC-010 production installed: eight MDER targets with 1,000 used ",
  "joint refits each; no support disposition changed; 1,017 non-MDER ",
  "artifacts remain byte-identical"
)
