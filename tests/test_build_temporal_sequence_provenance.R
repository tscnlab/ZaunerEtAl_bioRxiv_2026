options(warn = 2)

stopifnot(as.character(getRversion()) == "4.6.1")

source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/temporal_sequence_provenance.R")
source("scripts/pipeline/build_temporal_sequence_provenance.R")
source("scripts/pipeline/verify_temporal_sequence_provenance_artifacts.R")

canonical_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
test_root <- tempfile("nathealth-temporal-provenance-build-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE), add = TRUE)
canonical_inputs <- temporal_provenance_default_input_paths(canonical_root)

message("Checking root-independent upstream-manifest resolution")
outside_directory <- tempfile("nathealth-outside-cwd-")
dir.create(outside_directory)
on.exit(unlink(outside_directory, recursive = TRUE), add = TRUE)
old_directory <- setwd(outside_directory)
on.exit(setwd(old_directory), add = TRUE)
resolved_relative <- normalize_manifest_paths(
  "artifacts/12_manifests/coverage_artifacts.csv",
  canonical_root
)
stopifnot(
  identical(
    unname(resolved_relative),
    normalizePath(
      file.path(
        canonical_root,
        "artifacts/12_manifests/coverage_artifacts.csv"
      ),
      winslash = "/",
      mustWork = TRUE
    )
  )
)
input_audit <- verify_temporal_upstream_inputs(
  canonical_root,
  resolve_temporal_provenance_input_paths(NULL, canonical_root)
)
stopifnot(
  nrow(input_audit) == 6L,
  all(input_audit$status == "PASS"),
  all(!grepl("^/", input_audit$path)),
  all(!grepl("^/", input_audit$manifest_path))
)

message("Building from a non-project working directory")
build <- build_temporal_sequence_provenance_artifacts(
  root = test_root,
  input_paths = canonical_inputs,
  run_label = "full",
  input_root = canonical_root
)
artifact_paths <- temporal_provenance_artifact_paths(test_root)
scientific_paths <- unlist(
  artifact_paths[c(
    "source_bins_rds",
    "source_bins_csv",
    "wall_links_rds",
    "wall_links_csv"
  )],
  use.names = TRUE
)
scientific_hashes <- vapply(
  scientific_paths,
  artifact_sha256,
  character(1)
)
expected_scientific_hashes <- c(
  source_bins_rds = "87c05a2534479c02ed62e16bc74a4c8a6a061aff125a528e404f403b3e2ff46b",
  source_bins_csv = "88c7d2bb953a26290031e589ac4d51ca026889b0403299f8ba9db6b2f436b4b5",
  wall_links_rds = "a617893e74bbbd760950c185d0c548ff55692c52ded554a527dad2d72f2e6eb4",
  wall_links_csv = "b4e7623f2b930162f33f08f9e426e915f28226a32181c41e297e7d3eb0a25141"
)
first_manifest_sha256 <- artifact_sha256(artifact_paths$manifest)
stopifnot(
  nrow(build$source_bins) == 122982L,
  nrow(build$wall_links) == 122976L,
  sum(build$wall_links$source_bin_links == 2L) == 18L,
  sum(build$wall_links$source_bin_links == 0L) == 12L,
  is.null(attr(build$source_bins, "metric_settings")),
  is.null(attr(build$wall_links, "metric_settings")),
  identical(scientific_hashes, expected_scientific_hashes),
  identical(
    names(build$manifest),
    temporal_provenance_manifest_columns()
  ),
  !"written_utc" %in% names(build$manifest),
  all(!grepl("^/", build$manifest$path)),
  all(!grepl("=[/]", build$manifest$coverage_input_paths)),
  all(!grepl("=[/]", build$manifest$metric_input_paths)),
  all(!grepl("^/", build$manifest$coverage_manifest_path)),
  all(!grepl("^/", build$manifest$metric_manifest_path))
)

message("Independently verifying the isolated full-data build")
verified <- verify_temporal_sequence_provenance_artifacts(
  root = test_root,
  input_paths = canonical_inputs,
  input_root = canonical_root,
  stop_on_failure = FALSE
)
stopifnot(
  verified$status == "PASS",
  verified$source_bin_rows == 122982L,
  verified$wall_link_rows == 122976L,
  verified$fold_participant_days == 6L,
  verified$fold_wall_rows == 18L,
  verified$spring_gap_participant_days == 4L,
  verified$spring_gap_wall_rows == 12L,
  verified$non_one_to_one_source_bins == 36L,
  verified$manifest_rows == 4L
)

message("Checking byte-stable regeneration")
second_build <- build_temporal_sequence_provenance_artifacts(
  root = test_root,
  input_paths = canonical_inputs,
  run_label = "full",
  input_root = canonical_root
)
second_scientific_hashes <- vapply(
  scientific_paths,
  artifact_sha256,
  character(1)
)
stopifnot(
  identical(second_scientific_hashes, scientific_hashes),
  identical(
    artifact_sha256(second_build$paths$manifest),
    first_manifest_sha256
  )
)

message("Checking alternate-output-root portability")
alternate_root <- tempfile("nathealth-temporal-provenance-alternate-")
dir.create(alternate_root, recursive = TRUE)
on.exit(unlink(alternate_root, recursive = TRUE), add = TRUE)
alternate_build <- build_temporal_sequence_provenance_artifacts(
  root = alternate_root,
  input_paths = canonical_inputs,
  run_label = "full",
  input_root = canonical_root
)
alternate_paths <- temporal_provenance_artifact_paths(alternate_root)
alternate_scientific_hashes <- vapply(
  unlist(
    alternate_paths[c(
      "source_bins_rds",
      "source_bins_csv",
      "wall_links_rds",
      "wall_links_csv"
    )],
    use.names = TRUE
  ),
  artifact_sha256,
  character(1)
)
alternate_verified <- verify_temporal_sequence_provenance_artifacts(
  root = alternate_root,
  input_paths = canonical_inputs,
  input_root = canonical_root,
  stop_on_failure = FALSE
)
stopifnot(
  identical(alternate_scientific_hashes, scientific_hashes),
  identical(
    artifact_sha256(alternate_paths$manifest),
    first_manifest_sha256
  ),
  alternate_verified$status == "PASS"
)

message("Checking fail-closed provenance roots")
outside_input_error <- tryCatch(
  {
    temporal_provenance_relative_path(
      canonical_inputs[[1L]],
      test_root,
      "Synthetic outside input"
    )
    FALSE
  },
  error = function(error) {
    grepl(
      "outside its declared provenance root",
      conditionMessage(error),
      fixed = TRUE
    )
  }
)
verifier_outside_error <- tryCatch(
  {
    p06tp_relative_path(
      canonical_inputs[[1L]],
      test_root,
      "Synthetic verifier outside input"
    )
    FALSE
  },
  error = function(error) {
    grepl(
      "outside its declared provenance root",
      conditionMessage(error),
      fixed = TRUE
    )
  }
)
stopifnot(outside_input_error, verifier_outside_error)

message("Checking corruption failure after refreshing artifact hashes")
backup_root <- file.path(test_root, "artifact-backup")
dir.create(backup_root)
files_to_restore <- unlist(
  artifact_paths[c(
    "source_bins_rds",
    "source_bins_csv",
    "manifest"
  )],
  use.names = FALSE
)
backup_paths <- file.path(backup_root, basename(files_to_restore))
stopifnot(all(file.copy(files_to_restore, backup_paths)))
pre_corruption_hashes <- vapply(
  files_to_restore,
  artifact_sha256,
  character(1)
)

corrupted <- readRDS(artifact_paths$source_bins_rds)
target <- which(
  corrupted$sequence_eligible &
    corrupted$sequence_start_reason == "continuous"
)[1L]
stopifnot(!is.na(target))
corrupted$sequence_start_reason[[target]] <- "participant_start"
saveRDS(
  corrupted,
  artifact_paths$source_bins_rds,
  version = 3,
  compress = "xz"
)
readr::write_csv(
  temporal_provenance_csv_data(corrupted),
  artifact_paths$source_bins_csv,
  na = ""
)
manifest <- readr::read_csv(
  artifact_paths$manifest,
  show_col_types = FALSE,
  progress = FALSE
)
for (artifact_type in c(
  "true_utc_source_bins_rds",
  "true_utc_source_bins_csv"
)) {
  row <- manifest$artifact_type == artifact_type
  artifact_path <- if (grepl("_rds$", artifact_type)) {
    artifact_paths$source_bins_rds
  } else {
    artifact_paths$source_bins_csv
  }
  manifest$sha256[row] <- artifact_sha256(artifact_path)
  manifest$bytes[row] <- file.info(artifact_path)$size
}
readr::write_csv(manifest, artifact_paths$manifest, na = "")

corruption_result <- verify_temporal_sequence_provenance_artifacts(
  root = test_root,
  input_paths = canonical_inputs,
  input_root = canonical_root,
  stop_on_failure = FALSE
)
stopifnot(
  corruption_result$status == "FAIL",
  grepl(
    "Sequence field `sequence_start_reason`",
    corruption_result$error,
    fixed = TRUE
  )
)

stopifnot(all(file.copy(
  backup_paths,
  files_to_restore,
  overwrite = TRUE
)))
post_restore_hashes <- vapply(
  files_to_restore,
  artifact_sha256,
  character(1)
)
stopifnot(identical(pre_corruption_hashes, post_restore_hashes))

message("Temporal sequence-provenance builder/verifier tests passed")
