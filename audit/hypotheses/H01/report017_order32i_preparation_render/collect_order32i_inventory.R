#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, args[[1L]] %in% c("pre", "post", "postqa"))
phase <- args[[1L]]

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))
stopifnot(identical(as.character(getRversion()), "4.6.1"))

evidence_relative <-
  "audit/hypotheses/H01/report017_order32i_preparation_render"
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
  "report017_h01_order32i_dispatch_manifest.csv"
)
dispatch <- utils::read.csv(
  dispatch_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(dispatch) == 13L,
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
  dispatch$sha256 == dispatch$current_sha256 &
    dispatch$bytes == dispatch$current_bytes,
  "PASS",
  "FAIL"
)
if (identical(phase, "pre")) {
  stopifnot(all(dispatch$status == "PASS"))
} else {
  expected_changed <- dispatch$role == "stale_companion_html"
  dispatch$status[expected_changed & dispatch$status == "FAIL"] <-
    "EXPECTED_TARGET_CHANGE"
  stopifnot(
    sum(dispatch$status == "EXPECTED_TARGET_CHANGE") == 1L,
    all(dispatch$status[!expected_changed] == "PASS")
  )
}
write_csv(dispatch, paste0("order32i_dispatch_audit_", phase, ".csv"))

accepted_protected_path <- paste0(
  "audit/hypotheses/H01/report017_order32h_completion/",
  "order32h_post_protected_inventory.csv"
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
  accepted_protected_path
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
write_csv(protected, paste0("order32i_protected_inventory_", phase, ".csv"))

build_root <- normalizePath(
  file.path(root, "_build/nathealth"),
  winslash = "/",
  mustWork = TRUE
)
build_entries <- unique(c(
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
link_target <- Sys.readlink(build_entries)
is_link <- nzchar(link_target)
is_directory <- dir.exists(build_entries) & !is_link
is_file <- file.exists(build_entries) & !dir.exists(build_entries) & !is_link
build_info <- file.info(build_entries)
relative_path <- ifelse(
  build_entries == build_root,
  "",
  substring(build_entries, nchar(build_root) + 2L)
)
link_resolved <- rep("", length(build_entries))
link_safe <- rep(NA, length(build_entries))
if (any(is_link)) {
  for (index in which(is_link)) {
    candidate <- if (grepl("^/", link_target[[index]])) {
      link_target[[index]]
    } else {
      file.path(dirname(build_entries[[index]]), link_target[[index]])
    }
    resolved <- normalizePath(candidate, winslash = "/", mustWork = TRUE)
    link_resolved[[index]] <- resolved
    link_safe[[index]] <- identical(resolved, build_root) ||
      startsWith(resolved, paste0(build_root, "/"))
  }
  stopifnot(all(link_safe[is_link]))
}
sha256 <- rep(NA_character_, length(build_entries))
sha256[is_file] <- vapply(
  build_entries[is_file],
  artifact_sha256,
  character(1)
)
bytes <- rep(NA_real_, length(build_entries))
bytes[is_file] <- as.numeric(build_info$size[is_file])
build <- data.frame(
  path = relative_path,
  type = ifelse(is_link, "symlink", ifelse(is_directory, "directory", "file")),
  sha256 = sha256,
  bytes = bytes,
  mtime_utc = format_time(build_info$mtime),
  mode = sprintf("%04o", as.integer(build_info$mode)),
  link_target = link_target,
  link_resolved = link_resolved,
  link_safe = link_safe,
  stringsAsFactors = FALSE
)
build <- build[order(build$path), , drop = FALSE]
write_csv(build, paste0("order32i_build_inventory_", phase, ".csv"))
write_csv(
  build[build$type == "symlink", , drop = FALSE],
  paste0("order32i_build_symlink_audit_", phase, ".csv")
)

versions <- data.frame(
  component = c("R", "Quarto", "gt", "knitr", "xml2", "rvest"),
  version = c(
    as.character(getRversion()),
    system2("quarto", "--version", stdout = TRUE, stderr = FALSE)[[1L]],
    vapply(
      c("gt", "knitr", "xml2", "rvest"),
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  stringsAsFactors = FALSE
)
stopifnot(identical(versions$version[versions$component == "Quarto"], "1.9.37"))
write_csv(versions, paste0("order32i_versions_", phase, ".csv"))

summary <- data.frame(
  phase = phase,
  dispatch_rows = nrow(dispatch),
  dispatch_exact = sum(dispatch$status == "PASS"),
  dispatch_expected_target_changes =
    sum(dispatch$status == "EXPECTED_TARGET_CHANGE"),
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
  status = ifelse(
    identical(phase, "pre") && all(dispatch$status == "PASS") ||
      !identical(phase, "pre") &&
        sum(dispatch$status == "EXPECTED_TARGET_CHANGE") == 1L &&
        all(dispatch$status[dispatch$role != "stale_companion_html"] == "PASS"),
    "PASS",
    "FAIL"
  ),
  stringsAsFactors = FALSE
)
write_csv(summary, paste0("order32i_inventory_summary_", phase, ".csv"))

cat(sprintf(
  paste0(
    "phase=%s dispatch_exact=%d/%d target_changes=%d protected=%d build=%d files=%d ",
    "directories=%d symlinks=%d unsafe=%d\n"
  ),
  phase,
  sum(dispatch$status == "PASS"),
  nrow(dispatch),
  sum(dispatch$status == "EXPECTED_TARGET_CHANGE"),
  nrow(protected),
  nrow(build),
  sum(build$type == "file"),
  sum(build$type == "directory"),
  sum(build$type == "symlink"),
  summary$unsafe_symlinks
))
