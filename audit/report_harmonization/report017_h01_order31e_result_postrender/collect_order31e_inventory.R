args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, nzchar(args[[1L]]))
phase <- args[[1L]]

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(root, "scripts/pipeline/paths_io.R"))
stopifnot(identical(as.character(getRversion()), "4.6.1"))

evidence_dir <- file.path(
  root,
  "audit/report_harmonization/report017_h01_order31e_result_postrender"
)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

format_mtime <- function(value) {
  format(
    as.POSIXct(value, origin = "1970-01-01", tz = "UTC"),
    "%Y-%m-%d %H:%M:%S %Z",
    tz = "UTC"
  )
}

protected_reference <- read.csv(
  file.path(
    root,
    paste0(
      "audit/report_harmonization/",
      "report017_h01_order31_result_render/",
      "protected_1215_post31a_failure.csv"
    )
  ),
  stringsAsFactors = FALSE
)
stopifnot(nrow(protected_reference) == 1215L)
protected_paths <- file.path(root, protected_reference$path)
stopifnot(all(file.exists(protected_paths)))
protected_info <- file.info(protected_paths)
protected <- data.frame(
  path = protected_reference$path,
  sha256 = vapply(protected_paths, artifact_sha256, character(1)),
  bytes = as.numeric(protected_info$size),
  mtime_utc = format_mtime(protected_info$mtime),
  stringsAsFactors = FALSE
)
readr::write_csv(
  protected,
  file.path(evidence_dir, paste0("protected_inventory_", phase, ".csv")),
  na = ""
)

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
  for (i in which(is_link)) {
    candidate <- if (grepl("^/", link_target[[i]])) {
      link_target[[i]]
    } else {
      file.path(dirname(entries[[i]]), link_target[[i]])
    }
    resolved <- normalizePath(
      candidate,
      winslash = "/",
      mustWork = TRUE
    )
    link_resolved[[i]] <- resolved
    link_safe[[i]] <- identical(resolved, build_root) ||
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
readr::write_csv(
  build,
  file.path(evidence_dir, paste0("build_inventory_", phase, ".csv")),
  na = ""
)
readr::write_csv(
  build[build$type == "symlink", , drop = FALSE],
  file.path(evidence_dir, paste0("symlink_inventory_", phase, ".csv")),
  na = ""
)

pin_paths <- c(
  "notebooks/hypotheses/H01.qmd",
  "tests/hypotheses/H01/test_h01_reporting_inputs.R",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "_quarto-nathealth.yml",
  "scripts/report_harmonization/post_render_gt_html_semantics.R",
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  "tests/report_harmonization/test_post_render_gt_html_semantics.R",
  "artifacts/12_manifests/H01_reporting_artifacts.csv",
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv",
  "artifacts/09_tables/H01/stage3/H01_stage3_l10_noon_sensitivity.csv",
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html"
)
pin_files <- file.path(root, pin_paths)
stopifnot(all(file.exists(pin_files)))
pin_info <- file.info(pin_files)
pins <- data.frame(
  path = pin_paths,
  sha256 = vapply(pin_files, artifact_sha256, character(1)),
  bytes = as.numeric(pin_info$size),
  mtime_utc = format_mtime(pin_info$mtime),
  stringsAsFactors = FALSE
)
readr::write_csv(
  pins,
  file.path(evidence_dir, paste0("release_pins_", phase, ".csv")),
  na = ""
)

cat(sprintf(
  paste0(
    "phase=%s protected=%d build_entries=%d files=%d directories=%d ",
    "symlinks=%d unsafe_symlinks=%d\n"
  ),
  phase,
  nrow(protected),
  nrow(build),
  sum(build$type == "file"),
  sum(build$type == "directory"),
  sum(build$type == "symlink"),
  sum(build$type == "symlink" & !build$link_safe, na.rm = TRUE)
))
