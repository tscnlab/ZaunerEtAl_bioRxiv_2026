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

evidence_relative <- "audit/hypotheses/H01/report017_order32c_result_render"
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

audit_manifest <- function(relative, expected_rows) {
  manifest <- utils::read.csv(
    file.path(root, relative),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  stopifnot(nrow(manifest) == expected_rows)
  absolute <- file.path(root, manifest$path)
  stopifnot(all(file.exists(absolute)), all(!dir.exists(absolute)))
  info <- file.info(absolute)
  manifest$current_sha256 <- vapply(absolute, artifact_sha256, character(1))
  manifest$current_bytes <- as.numeric(info$size)
  manifest$status <- ifelse(
    manifest$sha256 == manifest$current_sha256 &
      manifest$bytes == manifest$current_bytes,
    "PASS",
    "FAIL"
  )
  stopifnot(all(manifest$status == "PASS"))
  manifest
}

dispatch_relative <-
  "audit/report_harmonization/report017_h01_order32c_dispatch_manifest.csv"
source_acceptance_relative <- paste0(
  "audit/report_harmonization/",
  "report017_h01_order32_source_independent_manifest.csv"
)
protected_reference_relative <- paste0(
  "audit/report_harmonization/",
  "report017_h01_order31_result_render/",
  "protected_1215_post31a_failure.csv"
)

dispatch <- audit_manifest(dispatch_relative, 12L)
source_acceptance <- audit_manifest(source_acceptance_relative, 25L)
write_csv(dispatch, paste0("dispatch_12_", phase, ".csv"))
write_csv(source_acceptance, paste0("source_acceptance_25_", phase, ".csv"))

protected_reference <- utils::read.csv(
  file.path(root, protected_reference_relative),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(nrow(protected_reference) == 1215L)
protected_paths <- sort(unique(c(
  protected_reference$path,
  dispatch$path,
  source_acceptance$path,
  protected_reference_relative,
  dispatch_relative,
  source_acceptance_relative
)))
protected_absolute <- file.path(root, protected_paths)
stopifnot(all(file.exists(protected_absolute)), all(!dir.exists(protected_absolute)))
protected_info <- file.info(protected_absolute)
protected <- data.frame(
  path = protected_paths,
  source_protected_1215 = protected_paths %in% protected_reference$path,
  source_dispatch_12 = protected_paths %in% dispatch$path,
  source_acceptance_25 = protected_paths %in% source_acceptance$path,
  sha256 = vapply(protected_absolute, artifact_sha256, character(1)),
  bytes = as.numeric(protected_info$size),
  mtime_utc = format_mtime(protected_info$mtime),
  stringsAsFactors = FALSE
)
write_csv(protected, paste0("protected_inventory_", phase, ".csv"))

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
  paste0("symlink_inventory_", phase, ".csv")
)

pin_paths <- c(
  "notebooks/hypotheses/H01.qmd",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "_quarto-nathealth.yml",
  "scripts/report_harmonization/post_render_gt_html_semantics.R",
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  "tests/report_harmonization/test_post_render_gt_html_semantics.R",
  "audit/report_harmonization/report017_h01_order32_source_independent_acceptance.md",
  "audit/report_harmonization/report017_h01_order32_source_independent_manifest.csv",
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html"
)
pin_absolute <- file.path(root, pin_paths)
stopifnot(all(file.exists(pin_absolute)), all(!dir.exists(pin_absolute)))
pin_info <- file.info(pin_absolute)
pins <- data.frame(
  path = pin_paths,
  sha256 = vapply(pin_absolute, artifact_sha256, character(1)),
  bytes = as.numeric(pin_info$size),
  mtime_utc = format_mtime(pin_info$mtime),
  stringsAsFactors = FALSE
)
write_csv(pins, paste0("release_pins_", phase, ".csv"))

versions <- data.frame(
  component = c("R", "Quarto", "gt", "xml2", "rvest", "knitr"),
  version = c(
    as.character(getRversion()),
    system2("quarto", "--version", stdout = TRUE)[[1L]],
    vapply(
      c("gt", "xml2", "rvest", "knitr"),
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
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
    "phase=%s protected=%d build_entries=%d files=%d directories=%d ",
    "symlinks=%d unsafe_symlinks=%d dispatch=%d source_acceptance=%d\n"
  ),
  phase,
  nrow(protected),
  nrow(build),
  sum(build$type == "file"),
  sum(build$type == "directory"),
  sum(build$type == "symlink"),
  sum(build$type == "symlink" & !build$link_safe, na.rm = TRUE),
  nrow(dispatch),
  nrow(source_acceptance)
))

