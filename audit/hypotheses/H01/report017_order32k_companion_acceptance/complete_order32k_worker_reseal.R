#!/usr/bin/env Rscript

stopifnot(identical(as.character(getRversion()), "4.6.1"))
root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H01/report017_order32k_companion_acceptance"
)
manifest_path <- "artifacts/12_manifests/H01_worker_artifacts.csv"
pre_path <- file.path(evidence_dir, "H01_worker_artifacts.pre.csv")
target_paths <- c(
  "scripts/hypotheses/H01/build_h01_preparation_report_manifest.R",
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html",
  "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv",
  "tests/hypotheses/H01/test_h01_preparation_report.R"
)
download_paths <- c(
  paste0(
    "_build/nathealth/audit/hypotheses/H01/",
    "H01_analysis_preparation_files/source-data/",
    "H01_preparation_fitted_sample_support.csv"
  ),
  paste0(
    "_build/nathealth/audit/hypotheses/H01/",
    "H01_analysis_preparation_files/source-data/",
    "H01_preparation_model_frame_retention.csv"
  )
)
historical_paths <- c(
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "_quarto-nathealth.yml"
)
stopifnot(
  artifact_sha256(pre_path) ==
    "882c1e63290384723b47d1bf67eb524c6a18e21d710eb60c989067bfe08c387c",
  artifact_sha256(manifest_path) ==
    "10b14e4725b4c0e04eae7be4241cacc415b84874bdb2e24b6a732fde45401d36",
  file.info(manifest_path)$size == 397566
)

connection <- file(manifest_path, open = "ab")
writeBin(as.raw(0x0a), connection)
close(connection)
stopifnot(file.info(manifest_path)$size == 397567)

pre_lines <- readLines(pre_path, warn = FALSE, encoding = "UTF-8")
post_lines <- readLines(manifest_path, warn = FALSE, encoding = "UTF-8")
stopifnot(
  length(pre_lines) == length(post_lines),
  sum(pre_lines != post_lines) == 5L
)
changed_indices <- which(pre_lines != post_lines)
before_rows <- do.call(rbind, lapply(seq_along(target_paths), function(index) {
  path <- target_paths[[index]]
  row_index <- which(startsWith(pre_lines, paste0(path, ",")))
  stopifnot(length(row_index) == 1L, row_index %in% changed_indices)
  fields <- strsplit(pre_lines[[row_index]], ",", fixed = TRUE)[[1L]]
  data.frame(
    sequence = index,
    path = path,
    sha256 = fields[[2L]],
    bytes = as.numeric(fields[[3L]]),
    producer = fields[[4L]],
    r_version = fields[[5L]],
    row_index = row_index,
    stringsAsFactors = FALSE
  )
}))
after_rows <- do.call(rbind, lapply(seq_along(target_paths), function(index) {
  path <- target_paths[[index]]
  row_index <- which(startsWith(post_lines, paste0(path, ",")))
  stopifnot(length(row_index) == 1L, row_index %in% changed_indices)
  fields <- strsplit(post_lines[[row_index]], ",", fixed = TRUE)[[1L]]
  stopifnot(
    fields[[2L]] == artifact_sha256(path),
    as.numeric(fields[[3L]]) == as.numeric(file.info(path)$size)
  )
  data.frame(
    sequence = index,
    path = path,
    sha256 = fields[[2L]],
    bytes = as.numeric(fields[[3L]]),
    producer = fields[[4L]],
    r_version = fields[[5L]],
    row_index = row_index,
    stringsAsFactors = FALSE
  )
}))
stopifnot(
  identical(before_rows$producer, after_rows$producer),
  identical(before_rows$r_version, after_rows$r_version),
  identical(before_rows$row_index, after_rows$row_index)
)

reverse_lines <- post_lines
reverse_lines[changed_indices] <- pre_lines[changed_indices]
reverse_path <- tempfile("order32k-worker-reverse-", fileext = ".csv")
on.exit(unlink(reverse_path), add = TRUE)
writeLines(reverse_lines, reverse_path, useBytes = TRUE)
stopifnot(
  artifact_sha256(reverse_path) == artifact_sha256(pre_path),
  file.info(reverse_path)$size == file.info(pre_path)$size
)

worker <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(
  nrow(worker) == 1659L,
  !anyDuplicated(worker$path),
  !any(worker$path == manifest_path)
)
exists <- file.exists(worker$path) & !dir.exists(worker$path)
current_sha <- rep(NA_character_, nrow(worker))
current_bytes <- rep(NA_real_, nrow(worker))
current_sha[exists] <- vapply(worker$path[exists], artifact_sha256, character(1))
current_bytes[exists] <- as.numeric(file.info(worker$path[exists])$size)
mismatch <- !exists | worker$sha256 != current_sha | worker$bytes != current_bytes
stopifnot(identical(sort(worker$path[mismatch]), sort(historical_paths)))

before_after <- merge(
  before_rows,
  after_rows,
  by = c("sequence", "path", "producer", "r_version", "row_index"),
  suffixes = c("_before", "_after"),
  sort = FALSE
)
before_after <- before_after[order(before_after$sequence), , drop = FALSE]
write.csv(
  before_after,
  file.path(evidence_dir, "order32k_worker_five_row_reseal.csv"),
  row.names = FALSE,
  na = ""
)

download_audit <- do.call(rbind, lapply(download_paths, function(path) {
  row_index <- which(startsWith(post_lines, paste0(path, ",")))
  stopifnot(length(row_index) == 1L, !row_index %in% changed_indices)
  fields <- strsplit(post_lines[[row_index]], ",", fixed = TRUE)[[1L]]
  data.frame(
    path = path,
    sha256 = fields[[2L]],
    bytes = as.numeric(fields[[3L]]),
    current_sha256 = artifact_sha256(path),
    current_bytes = as.numeric(file.info(path)$size),
    row_index = row_index,
    exact = fields[[2L]] == artifact_sha256(path) &&
      as.numeric(fields[[3L]]) == as.numeric(file.info(path)$size),
    stringsAsFactors = FALSE
  )
}))
stopifnot(all(download_audit$exact))
write.csv(
  download_audit,
  file.path(evidence_dir, "order32k_download_rows_unchanged.csv"),
  row.names = FALSE,
  na = ""
)

reverse_proof <- data.frame(
  item = c(
    "pre_worker",
    "intermediate_without_final_newline",
    "post_worker",
    "reverse_reconstruction"
  ),
  sha256 = c(
    artifact_sha256(pre_path),
    "10b14e4725b4c0e04eae7be4241cacc415b84874bdb2e24b6a732fde45401d36",
    artifact_sha256(manifest_path),
    artifact_sha256(reverse_path)
  ),
  bytes = c(
    file.info(pre_path)$size,
    397566,
    file.info(manifest_path)$size,
    file.info(reverse_path)$size
  ),
  classification = c(
    "SEALED_PREIMAGE",
    "HARNESS_FINAL_NEWLINE_STOP_REPAIRED",
    "ACCEPTED_FIVE_ROW_RESEAL",
    "EXACT_REVERSE_TO_PREIMAGE"
  ),
  stringsAsFactors = FALSE
)
write.csv(
  reverse_proof,
  file.path(evidence_dir, "order32k_worker_reverse_proof.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  data.frame(
    path = worker$path[mismatch],
    expected_sha256 = worker$sha256[mismatch],
    current_sha256 = current_sha[mismatch],
    expected_bytes = worker$bytes[mismatch],
    current_bytes = current_bytes[mismatch],
    classification = "ACCEPTED_HISTORICAL_TRANSITION",
    stringsAsFactors = FALSE
  ),
  file.path(evidence_dir, "order32k_worker_historical_mismatches_post.csv"),
  row.names = FALSE,
  na = ""
)
cat(sprintf(
  paste0(
    "worker_reseal=PASS changed=5 final_newline=RESTORED ",
    "live_exact=%d/%d historical=%d post=%s reverse=%s\n"
  ),
  sum(!mismatch),
  nrow(worker),
  sum(mismatch),
  artifact_sha256(manifest_path),
  artifact_sha256(reverse_path)
))
