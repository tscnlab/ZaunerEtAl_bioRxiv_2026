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
  "audit/hypotheses/H01/report017_order32j_no_render_finalization"
evidence_dir <- file.path(root, evidence_relative)
stopifnot(dir.exists(evidence_dir))

write_csv <- function(object, filename) {
  utils::write.csv(
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

dispatch_path <- paste0(
  "audit/report_harmonization/",
  "report017_h01_order32j_dispatch_manifest.csv"
)
dispatch <- utils::read.csv(
  dispatch_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(dispatch) == 28L,
  !anyDuplicated(dispatch$path),
  !any(dispatch$path == dispatch_path),
  all(file.exists(dispatch$path)),
  all(!dir.exists(dispatch$path))
)
dispatch$current_sha256 <- vapply(
  dispatch$path,
  artifact_sha256,
  character(1)
)
dispatch$current_bytes <- as.numeric(file.info(dispatch$path)$size)
dispatch$status <- ifelse(
  dispatch$current_sha256 == dispatch$sha256 &
    dispatch$current_bytes == dispatch$bytes,
  "PASS",
  "FAIL"
)
stopifnot(all(dispatch$status == "PASS"))
write_csv(dispatch, "order32j_dispatch_audit_pre.csv")

source_dir <-
  "artifacts/11_source_data/H01/preparation"
target_dir <- paste0(
  "_build/nathealth/audit/hypotheses/H01/",
  "H01_analysis_preparation_files/source-data"
)
download_names <- c(
  "H01_preparation_fitted_sample_support.csv",
  "H01_preparation_model_frame_retention.csv"
)
source_paths <- file.path(source_dir, download_names)
target_paths <- file.path(target_dir, download_names)
stopifnot(
  all(file.exists(source_paths)),
  all(!dir.exists(source_paths)),
  all(!nzchar(Sys.readlink(source_paths))),
  all(!file.exists(target_paths)),
  all(!dir.exists(target_paths))
)
source_info <- file.info(source_paths)
download_audit <- data.frame(
  filename = download_names,
  source_path = source_paths,
  source_sha256 = vapply(source_paths, artifact_sha256, character(1)),
  source_bytes = as.numeric(source_info$size),
  target_path = target_paths,
  target_exists = file.exists(target_paths),
  target_is_symlink = nzchar(Sys.readlink(target_paths)),
  status = "PASS_ABSENT_BEFORE_MUTATION",
  stringsAsFactors = FALSE
)
stopifnot(identical(
  download_audit$source_sha256,
  c(
    "760e634fd6139b8c6561d185c95fb5c06ef5b41637c7b20f8c61b0e627ff37c7",
    "28cc582f2778c849025f2ea77fee2036ce693378630d6f7e172adc0db6bb6d5b"
  )
))
write_csv(download_audit, "order32j_download_absence_pre.csv")

snapshot_map <- data.frame(
  source = c(
    "scripts/hypotheses/H01/build_h01_preparation_report_manifest.R",
    "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv",
    "artifacts/12_manifests/H01_worker_artifacts.csv"
  ),
  snapshot = file.path(
    evidence_relative,
    c(
      "build_h01_preparation_report_manifest.pre.R",
      "H01_preparation_report_manifest.pre.csv",
      "H01_worker_artifacts.pre.csv"
    )
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
snapshot_map$sha256 <- vapply(
  snapshot_map$source,
  artifact_sha256,
  character(1)
)
snapshot_map$bytes <- as.numeric(file.info(snapshot_map$source)$size)
write_csv(snapshot_map, "order32j_pre_mutation_snapshots.csv")

accepted_protected_path <- paste0(
  "audit/hypotheses/H01/report017_order32i_preparation_render/",
  "order32i_protected_inventory_postqa.csv"
)
accepted_protected <- utils::read.csv(
  accepted_protected_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
protected_paths <- sort(unique(c(
  accepted_protected$path,
  dispatch$path,
  dispatch_path,
  accepted_protected_path,
  source_paths
)))
protected_absolute <- file.path(root, protected_paths)
stopifnot(
  all(file.exists(protected_absolute)),
  all(!dir.exists(protected_absolute))
)
protected_info <- file.info(protected_absolute)
protected <- data.frame(
  path = protected_paths,
  sha256 = vapply(protected_absolute, artifact_sha256, character(1)),
  bytes = as.numeric(protected_info$size),
  mtime_utc = format_time(protected_info$mtime),
  mode = sprintf("%04o", as.integer(protected_info$mode)),
  stringsAsFactors = FALSE
)
write_csv(protected, "order32j_protected_inventory_pre.csv")

build_root <- normalizePath(
  file.path(root, "_build/nathealth"),
  winslash = "/",
  mustWork = TRUE
)
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
link_target <- Sys.readlink(entries)
is_link <- nzchar(link_target)
is_directory <- dir.exists(entries) & !is_link
is_file <- file.exists(entries) & !dir.exists(entries) & !is_link
entry_info <- file.info(entries)
relative_path <- ifelse(
  entries == build_root,
  "",
  substring(entries, nchar(build_root) + 2L)
)
link_resolved <- rep("", length(entries))
link_safe <- rep(NA, length(entries))
if (any(is_link)) {
  for (index in which(is_link)) {
    candidate <- if (grepl("^/", link_target[[index]])) {
      link_target[[index]]
    } else {
      file.path(dirname(entries[[index]]), link_target[[index]])
    }
    resolved <- normalizePath(candidate, winslash = "/", mustWork = TRUE)
    link_resolved[[index]] <- resolved
    link_safe[[index]] <- identical(resolved, build_root) ||
      startsWith(resolved, paste0(build_root, "/"))
  }
  stopifnot(all(link_safe[is_link]))
}
sha256 <- rep(NA_character_, length(entries))
sha256[is_file] <- vapply(entries[is_file], artifact_sha256, character(1))
bytes <- rep(NA_real_, length(entries))
bytes[is_file] <- as.numeric(entry_info$size[is_file])
build <- data.frame(
  path = relative_path,
  type = ifelse(is_link, "symlink", ifelse(is_directory, "directory", "file")),
  sha256 = sha256,
  bytes = bytes,
  mtime_utc = format_time(entry_info$mtime),
  mode = sprintf("%04o", as.integer(entry_info$mode)),
  link_target = link_target,
  link_resolved = link_resolved,
  link_safe = link_safe,
  stringsAsFactors = FALSE
)
build <- build[order(build$path), , drop = FALSE]
write_csv(build, "order32j_build_inventory_pre.csv")
write_csv(
  build[build$type == "symlink", , drop = FALSE],
  "order32j_build_symlink_audit_pre.csv"
)

versions <- data.frame(
  component = c("R", "Quarto", "dplyr", "tibble", "gt", "knitr", "xml2", "rvest"),
  version = c(
    as.character(getRversion()),
    system2("quarto", "--version", stdout = TRUE, stderr = FALSE)[[1L]],
    vapply(
      c("dplyr", "tibble", "gt", "knitr", "xml2", "rvest"),
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  stringsAsFactors = FALSE
)
stopifnot(
  identical(versions$version[versions$component == "Quarto"], "1.9.37"),
  identical(versions$version[versions$component == "R"], "4.6.1")
)
write_csv(versions, "order32j_versions.csv")

summary <- data.frame(
  dispatch_exact = sum(dispatch$status == "PASS"),
  dispatch_rows = nrow(dispatch),
  targets_absent = sum(!download_audit$target_exists),
  target_rows = nrow(download_audit),
  protected_paths = nrow(protected),
  build_entries = nrow(build),
  build_files = sum(build$type == "file"),
  build_directories = sum(build$type == "directory"),
  build_symlinks = sum(build$type == "symlink"),
  unsafe_symlinks = sum(
    build$type == "symlink" & !build$link_safe,
    na.rm = TRUE
  ),
  created_utc = format_time(Sys.time()),
  status = "PASS",
  stringsAsFactors = FALSE
)
write_csv(summary, "order32j_preflight_summary.csv")

cat(sprintf(
  paste0(
    "preflight=PASS dispatch=%d/%d absent=%d/%d protected=%d ",
    "build=%d files=%d directories=%d symlinks=%d unsafe=%d\n"
  ),
  summary$dispatch_exact,
  summary$dispatch_rows,
  summary$targets_absent,
  summary$target_rows,
  summary$protected_paths,
  summary$build_entries,
  summary$build_files,
  summary$build_directories,
  summary$build_symlinks,
  summary$unsafe_symlinks
))
