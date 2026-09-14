#!/usr/bin/env Rscript

stopifnot(identical(as.character(getRversion()), "4.6.1"))
root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))

evidence_relative <-
  "audit/hypotheses/H01/report017_order32k_companion_acceptance"
evidence_dir <- file.path(root, evidence_relative)
stopifnot(dir.exists(evidence_dir))
write_csv <- function(object, filename) {
  write.csv(
    object,
    file.path(evidence_dir, filename),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}
format_time <- function(value) {
  format(value, "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC")
}

dispatch_path <-
  "audit/report_harmonization/report017_h01_order32k_dispatch_manifest.csv"
dispatch <- read.csv(dispatch_path, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(
  nrow(dispatch) == 35L,
  !anyDuplicated(dispatch$path),
  !any(dispatch$path == dispatch_path),
  all(file.exists(dispatch$path)),
  all(!dir.exists(dispatch$path))
)
dispatch$current_sha256 <- vapply(dispatch$path, artifact_sha256, character(1))
dispatch$current_bytes <- as.numeric(file.info(dispatch$path)$size)
dispatch$status <- ifelse(
  dispatch$current_sha256 == dispatch$sha256 &
    dispatch$current_bytes == dispatch$bytes,
  "PASS",
  "FAIL"
)
stopifnot(all(dispatch$status == "PASS"))
write_csv(dispatch, "order32k_dispatch_audit_pre.csv")

manifest_path <-
  "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv"
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(
  nrow(manifest) == 65L,
  !anyDuplicated(manifest$path),
  !any(manifest$path == manifest_path),
  all(file.exists(manifest$path)),
  all(!dir.exists(manifest$path))
)
manifest$current_sha256 <- vapply(manifest$path, artifact_sha256, character(1))
manifest$current_bytes <- as.numeric(file.info(manifest$path)$size)
manifest$live_exact <- manifest$current_sha256 == manifest$sha256 &
  manifest$current_bytes == manifest$bytes
stopifnot(all(manifest$live_exact))
preimage <- read.csv(
  paste0(
    "audit/hypotheses/H01/report017_order32j_no_render_finalization/",
    "H01_preparation_report_manifest.pre.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
accepted_additions <- c(
  "scripts/hypotheses/H01/reconcile_h01_report016_deviations.R",
  "scripts/hypotheses/H01/refresh_h01_order32d_figures.R",
  paste0(
    "scripts/hypotheses/H01/",
    "refresh_h01_stage3_model_support_fdr_label.R"
  )
)
stopifnot(
  nrow(preimage) == 62L,
  identical(sort(setdiff(manifest$path, preimage$path)), sort(accepted_additions)),
  length(setdiff(preimage$path, manifest$path)) == 0L
)
write_csv(manifest, "order32k_preparation_manifest_audit_pre.csv")
write_csv(
  manifest[manifest$path %in% accepted_additions, , drop = FALSE],
  "order32k_accepted_manifest_additions.csv"
)

worker_path <- "artifacts/12_manifests/H01_worker_artifacts.csv"
worker <- read.csv(worker_path, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(
  nrow(worker) == 1659L,
  !anyDuplicated(worker$path),
  !any(worker$path == worker_path)
)
worker_exists <- file.exists(worker$path) & !dir.exists(worker$path)
worker_current_sha <- rep(NA_character_, nrow(worker))
worker_current_bytes <- rep(NA_real_, nrow(worker))
worker_current_sha[worker_exists] <- vapply(
  worker$path[worker_exists],
  artifact_sha256,
  character(1)
)
worker_current_bytes[worker_exists] <- as.numeric(
  file.info(worker$path[worker_exists])$size
)
worker_mismatch <- !worker_exists | worker$sha256 != worker_current_sha |
  worker$bytes != worker_current_bytes
expected_worker_mismatches <- c(
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html",
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "_quarto-nathealth.yml",
  manifest_path,
  "scripts/hypotheses/H01/build_h01_preparation_report_manifest.R"
)
stopifnot(identical(
  sort(worker$path[worker_mismatch]),
  sort(expected_worker_mismatches)
))
worker_audit <- data.frame(
  path = worker$path,
  expected_sha256 = worker$sha256,
  current_sha256 = worker_current_sha,
  expected_bytes = worker$bytes,
  current_bytes = worker_current_bytes,
  mismatch = worker_mismatch,
  stringsAsFactors = FALSE
)
write_csv(
  worker_audit[worker_audit$mismatch, , drop = FALSE],
  "order32k_worker_mismatches_pre.csv"
)

test_path <- "tests/hypotheses/H01/test_h01_preparation_report.R"
test_text <- paste(readLines(test_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
old_literal <- "17 prespecified light-exposure metrics"
new_literal <- "17-response package"
old_occurrences <- lengths(regmatches(
  test_text,
  gregexpr(old_literal, test_text, fixed = TRUE)
))
new_occurrences <- lengths(regmatches(
  test_text,
  gregexpr(new_literal, test_text, fixed = TRUE)
))
stopifnot(old_occurrences == 1L, new_occurrences == 0L)

snapshot_map <- data.frame(
  source = c(test_path, worker_path),
  snapshot = file.path(
    evidence_relative,
    c("test_h01_preparation_report.pre.R", "H01_worker_artifacts.pre.csv")
  ),
  stringsAsFactors = FALSE
)
stopifnot(all(!file.exists(snapshot_map$snapshot)))
copied <- file.copy(
  snapshot_map$source,
  snapshot_map$snapshot,
  overwrite = FALSE,
  copy.mode = TRUE
)
stopifnot(
  all(copied),
  identical(
    unname(vapply(snapshot_map$source, artifact_sha256, character(1))),
    unname(vapply(snapshot_map$snapshot, artifact_sha256, character(1)))
  ),
  identical(
    as.numeric(file.info(snapshot_map$source)$size),
    as.numeric(file.info(snapshot_map$snapshot)$size)
  )
)
snapshot_map$sha256 <- vapply(snapshot_map$source, artifact_sha256, character(1))
snapshot_map$bytes <- as.numeric(file.info(snapshot_map$source)$size)
write_csv(snapshot_map, "order32k_pre_mutation_snapshots.csv")

accepted_protected <- read.csv(
  paste0(
    "audit/hypotheses/H01/report017_order32j_no_render_finalization/",
    "order32j_protected_comparison_at_stop.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
protected_paths <- sort(unique(c(
  accepted_protected$path,
  dispatch$path,
  dispatch_path,
  manifest$path,
  worker_path
)))
stopifnot(
  all(file.exists(protected_paths)),
  all(!dir.exists(protected_paths))
)
protected_info <- file.info(protected_paths)
protected <- data.frame(
  path = protected_paths,
  sha256 = vapply(protected_paths, artifact_sha256, character(1)),
  bytes = as.numeric(protected_info$size),
  mtime_utc = format_time(protected_info$mtime),
  mode = sprintf("%04o", as.integer(protected_info$mode)),
  stringsAsFactors = FALSE
)
write_csv(protected, "order32k_protected_inventory_pre.csv")

build_root <- normalizePath("_build/nathealth", winslash = "/", mustWork = TRUE)
entries <- unique(c(
  build_root,
  list.files(
    build_root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  )
))
links <- Sys.readlink(entries)
is_link <- nzchar(links)
types <- ifelse(is_link, "symlink", ifelse(dir.exists(entries), "directory", "file"))
relative <- ifelse(entries == build_root, "", substring(entries, nchar(build_root) + 2L))
resolved <- rep("", length(entries))
safe <- rep(NA, length(entries))
if (any(is_link)) {
  for (index in which(is_link)) {
    candidate <- if (startsWith(links[[index]], "/")) {
      links[[index]]
    } else {
      file.path(dirname(entries[[index]]), links[[index]])
    }
    resolved[[index]] <- normalizePath(candidate, winslash = "/", mustWork = TRUE)
    safe[[index]] <- identical(resolved[[index]], build_root) ||
      startsWith(resolved[[index]], paste0(build_root, "/"))
  }
  stopifnot(all(safe[is_link]))
}
entry_info <- file.info(entries)
sha256 <- rep(NA_character_, length(entries))
bytes <- rep(NA_real_, length(entries))
is_file <- types == "file"
sha256[is_file] <- vapply(entries[is_file], artifact_sha256, character(1))
bytes[is_file] <- as.numeric(entry_info$size[is_file])
build <- data.frame(
  path = relative,
  type = types,
  sha256 = sha256,
  bytes = bytes,
  mtime_utc = format_time(entry_info$mtime),
  mode = sprintf("%04o", as.integer(entry_info$mode)),
  link_target = links,
  link_resolved = resolved,
  link_safe = safe,
  stringsAsFactors = FALSE
)
build <- build[order(build$path), , drop = FALSE]
write_csv(build, "order32k_build_inventory_pre.csv")
write_csv(
  build[build$type == "symlink", , drop = FALSE],
  "order32k_build_symlink_audit_pre.csv"
)

versions <- data.frame(
  component = c("R", "Quarto", "dplyr", "tibble", "gt", "knitr", "xml2", "rvest"),
  version = c(
    as.character(getRversion()),
    system2("quarto", "--version", stdout = TRUE, stderr = FALSE)[[1L]],
    vapply(
      c("dplyr", "tibble", "gt", "knitr", "xml2", "rvest"),
      function(package) as.character(packageVersion(package)),
      character(1)
    )
  ),
  stringsAsFactors = FALSE
)
stopifnot(
  versions$version[versions$component == "R"] == "4.6.1",
  versions$version[versions$component == "Quarto"] == "1.9.37"
)
write_csv(versions, "order32k_versions.csv")

summary <- data.frame(
  dispatch = sprintf("%d/%d", sum(dispatch$status == "PASS"), nrow(dispatch)),
  preparation_manifest = sprintf("%d/%d", sum(manifest$live_exact), nrow(manifest)),
  accepted_additions = length(accepted_additions),
  worker_mismatches = sum(worker_mismatch),
  old_literal_occurrences = old_occurrences,
  new_literal_occurrences = new_occurrences,
  protected_paths = nrow(protected),
  build_entries = nrow(build),
  build_symlinks = sum(build$type == "symlink"),
  unsafe_symlinks = sum(build$type == "symlink" & !build$link_safe, na.rm = TRUE),
  status = "PASS",
  stringsAsFactors = FALSE
)
write_csv(summary, "order32k_preflight_summary.csv")
cat(sprintf(
  paste0(
    "preflight=PASS dispatch=%s manifest=%s additions=%d worker_mismatch=%d ",
    "protected=%d build=%d symlinks=%d unsafe=%d\n"
  ),
  summary$dispatch,
  summary$preparation_manifest,
  summary$accepted_additions,
  summary$worker_mismatches,
  summary$protected_paths,
  summary$build_entries,
  summary$build_symlinks,
  summary$unsafe_symlinks
))
