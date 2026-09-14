#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, args[[1L]] %in% c("prerender", "postrender", "postqa"))
phase <- args[[1L]]

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))
stopifnot(identical(as.character(getRversion()), "4.6.1"))

evidence_relative <- "audit/hypotheses/H02/report017_order33f_result_render"
evidence_dir <- file.path(root, evidence_relative)
stopifnot(dir.exists(evidence_dir))

format_mtime <- function(value) {
  format(
    as.POSIXct(value, origin = "1970-01-01", tz = "UTC"),
    "%Y-%m-%d %H:%M:%OS6 %Z",
    tz = "UTC"
  )
}

write_csv <- function(object, filename) {
  utils::write.csv(
    object,
    file.path(evidence_dir, filename),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

hash_if_file <- function(path) {
  exists <- file.exists(path) && !dir.exists(path) && !nzchar(Sys.readlink(path))
  if (!exists) return("")
  artifact_sha256(path)
}

dispatch_relative <-
  "audit/report_harmonization/report017_h02_order33f_dispatch_manifest.csv"
acceptance_relative <-
  "audit/report_harmonization/report017_h02_order33_source_acceptance_manifest.csv"
dispatch <- utils::read.csv(
  dispatch_relative,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
acceptance <- utils::read.csv(
  acceptance_relative,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(nrow(dispatch) == 20L, nrow(acceptance) == 15L)

audit_expected <- function(object, mutable_roles = character()) {
  absolute <- ifelse(
    startsWith(object$path, "/"),
    object$path,
    file.path(root, object$path)
  )
  info <- file.info(absolute)
  object$current_sha256 <- vapply(absolute, hash_if_file, character(1))
  object$current_bytes <- as.numeric(info$size)
  object$exact <- object$sha256 == object$current_sha256 &
    object$bytes == object$current_bytes
  object$required <- if ("role" %in% names(object)) {
    !object$role %in% mutable_roles
  } else {
    rep(TRUE, nrow(object))
  }
  object$status <- ifelse(object$exact, "PASS", ifelse(object$required, "FAIL", "DRIFT_ALLOWED"))
  object
}

dispatch_mutable_roles <- c("mutable_coordination_evidence")
if (!identical(phase, "prerender")) {
  dispatch_mutable_roles <- c(dispatch_mutable_roles, "stale_render_target")
}
dispatch_audit <- audit_expected(dispatch, dispatch_mutable_roles)
acceptance_audit <- audit_expected(acceptance)
stopifnot(all(dispatch_audit$status[dispatch_audit$required] == "PASS"))
stopifnot(all(acceptance_audit$status == "PASS"))
write_csv(dispatch_audit, paste0("dispatch_20_", phase, ".csv"))
write_csv(acceptance_audit, paste0("source_acceptance_15_", phase, ".csv"))

manifest_specs <- data.frame(
  manifest_id = c("worker", "analysis", "preparation"),
  path = c(
    "artifacts/12_manifests/H02/H02_worker_output_hashes.csv",
    "artifacts/12_manifests/H02/H02_analysis_manifest.csv",
    "artifacts/12_manifests/H02/H02_preparation_report_manifest.csv"
  ),
  stringsAsFactors = FALSE
)
manifest_rows <- do.call(rbind, lapply(seq_len(nrow(manifest_specs)), function(index) {
  current <- utils::read.csv(
    manifest_specs$path[[index]],
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  stopifnot(all(c("path", "sha256", "bytes") %in% names(current)))
  absolute <- file.path(root, current$path)
  info <- file.info(absolute)
  data.frame(
    manifest_id = manifest_specs$manifest_id[[index]],
    manifest_path = manifest_specs$path[[index]],
    path = current$path,
    expected_sha256 = current$sha256,
    expected_bytes = current$bytes,
    exists = file.exists(absolute),
    current_sha256 = vapply(absolute, hash_if_file, character(1)),
    current_bytes = as.numeric(info$size),
    stringsAsFactors = FALSE
  )
}))
manifest_rows$historical_exact <- manifest_rows$exists &
  manifest_rows$expected_sha256 == manifest_rows$current_sha256 &
  manifest_rows$expected_bytes == manifest_rows$current_bytes
write_csv(manifest_rows, paste0("manifest_rows_", phase, ".csv"))

protected_reference <- utils::read.csv(
  "audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_protected_inventory.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(nrow(protected_reference) == 30L)

explicit_paths <- c(
  dispatch$path,
  acceptance$path,
  dispatch_relative,
  acceptance_relative,
  manifest_specs$path,
  "audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_protected_inventory.csv",
  "renv.lock"
)
accepted_paths <- sort(unique(c(
  explicit_paths,
  manifest_rows$path,
  protected_reference$path
)))
accepted_absolute <- ifelse(
  startsWith(accepted_paths, "/"),
  accepted_paths,
  file.path(root, accepted_paths)
)
accepted_info <- file.info(accepted_absolute)
accepted_link <- Sys.readlink(accepted_absolute)
accepted_type <- ifelse(
  nzchar(accepted_link),
  "symlink",
  ifelse(
    dir.exists(accepted_absolute),
    "directory",
    ifelse(file.exists(accepted_absolute), "file", "missing")
  )
)
accepted_class <- ifelse(
  accepted_paths == "_build/nathealth/notebooks/hypotheses/H02.html",
  "target_html",
  ifelse(
    startsWith(accepted_paths, "_build/nathealth/notebooks/hypotheses/H02_files/"),
    "target_resource",
    ifelse(
      startsWith(accepted_paths, "_build/nathealth/artifacts/") &
        grepl("/H02/", accepted_paths, fixed = TRUE),
      "target_resource",
      ifelse(
        accepted_paths %in% c("_build/nathealth/search.json", "_build/nathealth/sitemap.xml"),
        "site_index",
        "protected"
      )
    )
  )
)
accepted <- data.frame(
  path = accepted_paths,
  classification = accepted_class,
  type = accepted_type,
  exists = file.exists(accepted_absolute),
  sha256 = vapply(accepted_absolute, hash_if_file, character(1)),
  bytes = as.numeric(accepted_info$size),
  mtime_utc = format_mtime(accepted_info$mtime),
  mode = sprintf("%04o", as.integer(accepted_info$mode)),
  link_target = accepted_link,
  stringsAsFactors = FALSE
)
write_csv(accepted, paste0("accepted_inventory_", phase, ".csv"))

build_root <- normalizePath(
  file.path(root, "_build/nathealth"),
  winslash = "/",
  mustWork = TRUE
)
entries <- c(
  build_root,
  list.files(
    build_root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  )
)
entries <- unique(entries)
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
    candidate <- if (startsWith(link_target[[index]], "/")) {
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
sha256 <- rep("", length(entries))
sha256[is_file] <- vapply(entries[is_file], artifact_sha256, character(1))
bytes <- rep(NA_real_, length(entries))
bytes[is_file] <- as.numeric(entry_info$size[is_file])
build <- data.frame(
  path = relative_path,
  type = ifelse(is_link, "symlink", ifelse(is_directory, "directory", "file")),
  sha256 = sha256,
  bytes = bytes,
  mtime_utc = format_mtime(entry_info$mtime),
  mode = sprintf("%04o", as.integer(entry_info$mode)),
  link_target = link_target,
  link_resolved = link_resolved,
  link_safe = link_safe,
  stringsAsFactors = FALSE
)
build <- build[order(build$path), , drop = FALSE]
write_csv(build, paste0("build_inventory_", phase, ".csv"))
write_csv(
  build[build$type == "symlink", , drop = FALSE],
  paste0("build_symlink_inventory_", phase, ".csv")
)

versions <- data.frame(
  component = c("R", "Quarto"),
  version = c(
    as.character(getRversion()),
    system2("quarto", "--version", stdout = TRUE)[[1L]]
  ),
  stringsAsFactors = FALSE
)
write_csv(versions, paste0("versions_", phase, ".csv"))

if (identical(phase, "prerender")) {
  seal_path <- file.path(evidence_dir, "prerender_inventory_seal.csv")
  seal_files <- sort(list.files(
    evidence_dir,
    full.names = TRUE,
    recursive = FALSE,
    all.files = FALSE
  ))
  seal_files <- setdiff(seal_files, seal_path)
  seal <- data.frame(
    path = substring(seal_files, nchar(root) + 2L),
    sha256 = vapply(seal_files, artifact_sha256, character(1)),
    bytes = as.numeric(file.info(seal_files)$size),
    stringsAsFactors = FALSE
  )
  write_csv(seal, basename(seal_path))
}

cat(sprintf(
  paste0(
    "phase=%s accepted=%d manifest_rows=%d build_entries=%d files=%d ",
    "directories=%d symlinks=%d unsafe_symlinks=%d dispatch=%d acceptance=%d\n"
  ),
  phase,
  nrow(accepted),
  nrow(manifest_rows),
  nrow(build),
  sum(build$type == "file"),
  sum(build$type == "directory"),
  sum(build$type == "symlink"),
  sum(build$type == "symlink" & !build$link_safe, na.rm = TRUE),
  nrow(dispatch),
  nrow(acceptance)
))
