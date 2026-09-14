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
  artifact_sha256(manifest_path) == artifact_sha256(pre_path),
  all(file.exists(target_paths)),
  all(file.exists(download_paths))
)

read_raw <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, what = "raw", n = as.numeric(file.info(path)$size))
}
pre_text <- rawToChar(read_raw(pre_path))
pre_lines <- strsplit(pre_text, "\n", fixed = TRUE)[[1L]]
current_text <- rawToChar(read_raw(manifest_path))
current_lines <- strsplit(current_text, "\n", fixed = TRUE)[[1L]]
stopifnot(identical(pre_lines, current_lines))

before_rows <- vector("list", length(target_paths))
after_rows <- vector("list", length(target_paths))
names(before_rows) <- names(after_rows) <- target_paths
for (index in seq_along(target_paths)) {
  path <- target_paths[[index]]
  row_index <- which(startsWith(current_lines, paste0(path, ",")))
  stopifnot(length(row_index) == 1L)
  fields <- strsplit(current_lines[[row_index]], ",", fixed = TRUE)[[1L]]
  stopifnot(length(fields) == 5L, identical(fields[[1L]], path))
  before_rows[[index]] <- data.frame(
    sequence = index,
    path = path,
    sha256 = fields[[2L]],
    bytes = as.numeric(fields[[3L]]),
    producer = fields[[4L]],
    r_version = fields[[5L]],
    row_index = row_index,
    stringsAsFactors = FALSE
  )
  fields[[2L]] <- artifact_sha256(path)
  fields[[3L]] <- as.character(as.numeric(file.info(path)$size))
  current_lines[[row_index]] <- paste(fields, collapse = ",")
  after_rows[[index]] <- data.frame(
    sequence = index,
    path = path,
    sha256 = fields[[2L]],
    bytes = as.numeric(fields[[3L]]),
    producer = fields[[4L]],
    r_version = fields[[5L]],
    row_index = row_index,
    stringsAsFactors = FALSE
  )
}
before_rows <- do.call(rbind, before_rows)
after_rows <- do.call(rbind, after_rows)
stopifnot(
  identical(before_rows$producer, after_rows$producer),
  identical(before_rows$r_version, after_rows$r_version),
  identical(before_rows$row_index, after_rows$row_index),
  sum(pre_lines != current_lines) == 5L
)

download_before <- do.call(rbind, lapply(download_paths, function(path) {
  row_index <- which(startsWith(pre_lines, paste0(path, ",")))
  stopifnot(length(row_index) == 1L)
  fields <- strsplit(pre_lines[[row_index]], ",", fixed = TRUE)[[1L]]
  data.frame(
    path = path,
    sha256 = fields[[2L]],
    bytes = as.numeric(fields[[3L]]),
    current_sha256 = artifact_sha256(path),
    current_bytes = as.numeric(file.info(path)$size),
    row_index = row_index,
    stringsAsFactors = FALSE
  )
}))
download_before$exact <- download_before$sha256 == download_before$current_sha256 &
  download_before$bytes == download_before$current_bytes
stopifnot(all(download_before$exact))

new_text <- paste(current_lines, collapse = "\n")
temporary <- tempfile(
  pattern = "H01_worker_artifacts.order32k.",
  tmpdir = dirname(manifest_path)
)
on.exit(unlink(temporary), add = TRUE)
writeBin(charToRaw(new_text), temporary)
Sys.chmod(temporary, mode = file.info(manifest_path)$mode)
stopifnot(file.rename(temporary, manifest_path))

post_text <- rawToChar(read_raw(manifest_path))
post_lines <- strsplit(post_text, "\n", fixed = TRUE)[[1L]]
stopifnot(
  identical(post_lines, current_lines),
  length(post_lines) == length(pre_lines),
  sum(post_lines != pre_lines) == 5L
)

reverse_lines <- post_lines
for (path in target_paths) {
  post_index <- which(startsWith(reverse_lines, paste0(path, ",")))
  pre_index <- which(startsWith(pre_lines, paste0(path, ",")))
  stopifnot(length(post_index) == 1L, length(pre_index) == 1L)
  reverse_lines[[post_index]] <- pre_lines[[pre_index]]
}
reverse_path <- tempfile("order32k-worker-reverse-", fileext = ".csv")
on.exit(unlink(reverse_path), add = TRUE)
writeBin(charToRaw(paste(reverse_lines, collapse = "\n")), reverse_path)
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
write.csv(
  download_before,
  file.path(evidence_dir, "order32k_download_rows_unchanged.csv"),
  row.names = FALSE,
  na = ""
)
reverse_proof <- data.frame(
  item = c("pre_worker", "post_worker", "reverse_reconstruction"),
  sha256 = c(
    artifact_sha256(pre_path),
    artifact_sha256(manifest_path),
    artifact_sha256(reverse_path)
  ),
  bytes = c(
    file.info(pre_path)$size,
    file.info(manifest_path)$size,
    file.info(reverse_path)$size
  ),
  exact_to_pre = c(TRUE, FALSE, TRUE),
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
  "worker_reseal=PASS changed=5 live_exact=%d/%d historical=%d post=%s\n",
  sum(!mismatch),
  nrow(worker),
  sum(mismatch),
  artifact_sha256(manifest_path)
))
