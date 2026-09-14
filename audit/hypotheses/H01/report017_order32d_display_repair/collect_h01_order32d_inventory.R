#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
stopifnot(
  length(args) == 1L,
  args[[1L]] %in% c(
    "prechange", "postquarantine", "prerender", "postrender", "postqa"
  )
)
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
  "audit/hypotheses/H01/report017_order32d_display_repair"
evidence_dir <- file.path(root, evidence_relative)
stopifnot(dir.exists(evidence_dir))

format_time <- function(value) {
  output <- rep(NA_character_, length(value))
  available <- !is.na(value)
  output[available] <- format(
    as.POSIXct(value[available], origin = "1970-01-01", tz = "UTC"),
    "%Y-%m-%d %H:%M:%OS6 UTC",
    tz = "UTC"
  )
  output
}

birth_epoch <- function(paths) {
  vapply(paths, function(path) {
    if (!file.exists(path) && !dir.exists(path)) return(NA_real_)
    value <- suppressWarnings(system2(
      "stat",
      c("-f", "%B", shQuote(path)),
      stdout = TRUE,
      stderr = FALSE
    ))
    if (!length(value)) return(NA_real_)
    suppressWarnings(as.numeric(value[[1L]]))
  }, numeric(1))
}

write_csv <- function(object, name) {
  utils::write.csv(
    object,
    file.path(evidence_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

inventory_paths <- function(relative_paths, build_root = NULL) {
  relative_paths <- sort(unique(relative_paths))
  absolute_paths <- if (is.null(build_root)) {
    file.path(root, relative_paths)
  } else {
    ifelse(
      relative_paths == "",
      build_root,
      file.path(build_root, relative_paths)
    )
  }
  link_target <- Sys.readlink(absolute_paths)
  is_link <- !is.na(link_target) & nzchar(link_target)
  present <- file.exists(absolute_paths) | dir.exists(absolute_paths) | is_link
  is_directory <- dir.exists(absolute_paths) & !is_link
  is_file <- file.exists(absolute_paths) & !dir.exists(absolute_paths) & !is_link
  info <- file.info(absolute_paths)
  sha256 <- rep(NA_character_, length(absolute_paths))
  sha256[is_file] <- vapply(absolute_paths[is_file], artifact_sha256, character(1))
  link_resolved <- rep(NA_character_, length(absolute_paths))
  link_safe <- rep(NA, length(absolute_paths))
  if (any(is_link)) {
    for (index in which(is_link)) {
      candidate <- if (grepl("^/", link_target[[index]])) {
        link_target[[index]]
      } else {
        file.path(dirname(absolute_paths[[index]]), link_target[[index]])
      }
      resolved <- normalizePath(candidate, winslash = "/", mustWork = TRUE)
      link_resolved[[index]] <- resolved
      if (!is.null(build_root)) {
        link_safe[[index]] <- identical(resolved, build_root) ||
          startsWith(resolved, paste0(build_root, "/"))
      }
    }
  }
  data.frame(
    path = relative_paths,
    present = present,
    type = ifelse(
      !present,
      "missing",
      ifelse(is_link, "symlink", ifelse(is_directory, "directory", "file"))
    ),
    sha256 = sha256,
    bytes = ifelse(is_file, as.numeric(info$size), NA_real_),
    mode = ifelse(present, sprintf("%04o", as.integer(info$mode)), NA_character_),
    mtime_utc = format_time(as.numeric(info$mtime)),
    ctime_utc = format_time(as.numeric(info$ctime)),
    birthtime_utc = format_time(birth_epoch(absolute_paths)),
    link_target = ifelse(is_link, link_target, NA_character_),
    link_resolved = link_resolved,
    link_safe = link_safe,
    stringsAsFactors = FALSE
  )
}

dispatch_relative <-
  "audit/report_harmonization/report017_h01_order32d_dispatch_manifest.csv"
prior_protected_relative <- paste0(
  "audit/hypotheses/H01/report017_order32c_result_render/",
  "protected_inventory_postqa.csv"
)
manifest_relatives <- c(
  "artifacts/12_manifests/H01_reporting_artifacts.csv",
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv",
  "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv",
  "artifacts/12_manifests/H01_worker_artifacts.csv"
)

dispatch <- utils::read.csv(
  file.path(root, dispatch_relative),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
prior_protected <- utils::read.csv(
  file.path(root, prior_protected_relative),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
manifest_paths <- unlist(lapply(manifest_relatives, function(relative) {
  manifest <- utils::read.csv(
    file.path(root, relative),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  stopifnot("path" %in% names(manifest))
  manifest$path
}), use.names = FALSE)

future_scope <- c(
  "scripts/hypotheses/H01/refresh_h01_order32d_figures.R",
  "tests/hypotheses/H01/test_h01_order32d_display_repair.R",
  file.path(evidence_relative, "run_h01_order32d_semantic_audit.R")
)
quarantined_build_paths <- c(
  "_build/nathealth/artifacts/10_figures/H01/stage3/H01_stage3_model_support 2.png",
  "_build/nathealth/notebooks/hypotheses/H01 2.html",
  paste0(
    "_build/nathealth/site_libs/bootstrap/",
    "bootstrap-a2a938b4dd5711f7a799c87bd16ba44c.min 2.css"
  )
)
protected_paths <- sort(unique(c(
  prior_protected$path,
  dispatch$path,
  dispatch_relative,
  prior_protected_relative,
  manifest_relatives,
  manifest_paths,
  future_scope
)))
protected <- inventory_paths(protected_paths)
write_csv(protected, paste0("protected_inventory_", phase, ".csv"))

build_root <- normalizePath(
  file.path(root, "_build/nathealth"),
  winslash = "/",
  mustWork = TRUE
)
build_absolute <- c(
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
build_absolute <- sort(unique(build_absolute))
build_relative <- ifelse(
  build_absolute == build_root,
  "",
  substring(build_absolute, nchar(build_root) + 2L)
)
build <- inventory_paths(build_relative, build_root = build_root)
write_csv(build, paste0("build_inventory_", phase, ".csv"))
write_csv(
  build[build$type == "symlink", , drop = FALSE],
  paste0("build_symlinks_", phase, ".csv")
)

stopifnot(
  all(protected$present[
    protected$path %in% c(dispatch$path, manifest_relatives) &
      (phase == "prechange" | !protected$path %in% quarantined_build_paths)
  ]),
  !any(build$type == "symlink" & !build$link_safe, na.rm = TRUE)
)

summary <- data.frame(
  phase = phase,
  protected_rows = nrow(protected),
  protected_present = sum(protected$present),
  protected_missing_future_scope = sum(!protected$present),
  build_entries = nrow(build),
  build_files = sum(build$type == "file"),
  build_directories = sum(build$type == "directory"),
  build_symlinks = sum(build$type == "symlink"),
  unsafe_build_symlinks = sum(build$type == "symlink" & !build$link_safe, na.rm = TRUE),
  stringsAsFactors = FALSE
)
write_csv(summary, paste0("inventory_summary_", phase, ".csv"))

cat(sprintf(
  paste0(
    "phase=%s protected=%d present=%d missing=%d build=%d files=%d ",
    "directories=%d symlinks=%d unsafe=%d\n"
  ),
  phase,
  nrow(protected),
  sum(protected$present),
  sum(!protected$present),
  nrow(build),
  sum(build$type == "file"),
  sum(build$type == "directory"),
  sum(build$type == "symlink"),
  sum(build$type == "symlink" & !build$link_safe, na.rm = TRUE)
))
