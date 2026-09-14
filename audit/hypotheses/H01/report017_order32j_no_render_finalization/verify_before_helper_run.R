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
  "audit/hypotheses/H01/report017_order32j_no_render_finalization"
)
helper <- "scripts/hypotheses/H01/build_h01_preparation_report_manifest.R"
helper_sha <- "da6e5c743d8eb693b35453b7a67344fb012344144697d2d0c0b94a0d91cbdcbf"
helper_bytes <- 8460
dispatch <- read.csv(
  "audit/report_harmonization/report017_h01_order32j_dispatch_manifest.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
dispatch$current_sha256 <- vapply(dispatch$path, artifact_sha256, character(1))
dispatch$current_bytes <- as.numeric(file.info(dispatch$path)$size)
dispatch$expected_status <- ifelse(
  dispatch$path == helper,
  dispatch$current_sha256 == helper_sha & dispatch$current_bytes == helper_bytes,
  dispatch$current_sha256 == dispatch$sha256 &
    dispatch$current_bytes == dispatch$bytes
)
stopifnot(nrow(dispatch) == 28L, all(dispatch$expected_status))

targets <- file.path(
  paste0(
    "_build/nathealth/audit/hypotheses/H01/",
    "H01_analysis_preparation_files/source-data"
  ),
  c(
    "H01_preparation_fitted_sample_support.csv",
    "H01_preparation_model_frame_retention.csv"
  )
)
target_links <- Sys.readlink(targets)
stopifnot(
  all(!file.exists(targets)),
  all(is.na(target_links) | !nzchar(target_links))
)

protected_pre <- read.csv(
  file.path(evidence_dir, "order32j_protected_inventory_pre.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
protected_pre$current_sha256 <- vapply(
  protected_pre$path,
  artifact_sha256,
  character(1)
)
protected_pre$current_bytes <- as.numeric(file.info(protected_pre$path)$size)
protected_pre$expected_status <- ifelse(
  protected_pre$path == helper,
  protected_pre$current_sha256 == helper_sha &
    protected_pre$current_bytes == helper_bytes,
  protected_pre$current_sha256 == protected_pre$sha256 &
    protected_pre$current_bytes == protected_pre$bytes
)
stopifnot(all(protected_pre$expected_status))

build_pre <- read.csv(
  file.path(evidence_dir, "order32j_build_inventory_pre.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
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
types <- ifelse(
  nzchar(links),
  "symlink",
  ifelse(dir.exists(entries), "directory", "file")
)
paths <- ifelse(
  entries == build_root,
  "",
  substring(entries, nchar(build_root) + 2L)
)
current <- data.frame(path = paths, type = types, stringsAsFactors = FALSE)
current$sha256 <- NA_character_
current$bytes <- NA_real_
file_rows <- current$type == "file"
current$sha256[file_rows] <- vapply(
  entries[file_rows],
  artifact_sha256,
  character(1)
)
current$bytes[file_rows] <- as.numeric(file.info(entries[file_rows])$size)
current <- current[order(current$path), , drop = FALSE]
build_pre_sha256 <- build_pre$sha256
build_pre_sha256[is.na(build_pre_sha256) | build_pre_sha256 == ""] <- NA_character_
same_sha256 <- ifelse(
  is.na(current$sha256) & is.na(build_pre_sha256),
  TRUE,
  ifelse(
    is.na(current$sha256) | is.na(build_pre_sha256),
    FALSE,
    current$sha256 == build_pre_sha256
  )
)
same_bytes <- ifelse(
  is.na(current$bytes) & is.na(build_pre$bytes),
  TRUE,
  ifelse(
    is.na(current$bytes) | is.na(build_pre$bytes),
    FALSE,
    current$bytes == build_pre$bytes
  )
)
stopifnot(
  identical(current$path, build_pre$path),
  identical(current$type, build_pre$type),
  all(same_sha256),
  all(same_bytes)
)

write.csv(
  dispatch,
  file.path(evidence_dir, "order32j_dispatch_audit_before_helper.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  protected_pre,
  file.path(evidence_dir, "order32j_protected_check_before_helper.csv"),
  row.names = FALSE,
  na = ""
)
summary <- data.frame(
  dispatch = sprintf("%d/%d", sum(dispatch$expected_status), nrow(dispatch)),
  protected = sprintf(
    "%d/%d",
    sum(protected_pre$expected_status),
    nrow(protected_pre)
  ),
  build = sprintf("%d/%d", nrow(current), nrow(build_pre)),
  downloads_absent = sprintf("%d/%d", sum(!file.exists(targets)), length(targets)),
  status = "PASS",
  stringsAsFactors = FALSE
)
write.csv(
  summary,
  file.path(evidence_dir, "order32j_before_helper_summary.csv"),
  row.names = FALSE,
  na = ""
)
cat(
  sprintf(
    "before_helper=PASS dispatch=%s protected=%s build=%s downloads_absent=%s\n",
    summary$dispatch,
    summary$protected,
    summary$build,
    summary$downloads_absent
  )
)
