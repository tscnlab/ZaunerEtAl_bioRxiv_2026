#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

assert_all <- function(value, message) {
  if (!length(value) || !all(value)) stop(message, call. = FALSE)
}

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("R 4.6.1 required, found %s", getRversion())
)

suppressPackageStartupMessages(library(digest))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
working_dir <- normalizePath(
  Sys.getenv("ORDER55_WORKING_DIR"),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

file_bytes <- function(path) unname(file.info(path)$size)

write_evidence <- function(object, name) {
  utils::write.csv(
    object,
    file.path(working_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

manifest_rel <- "artifacts/12_manifests/H08/H08_preparation_report_manifest.csv"
manifest_path <- file.path(root, manifest_rel)
source_rel <- "audit/hypotheses/H08/H08_analysis_preparation.qmd"
build_source_rel <- paste0(
  "_build/nathealth/audit/hypotheses/H08/",
  "H08_analysis_preparation.qmd"
)
helper_rel <- "scripts/hypotheses/H08/build_h08_preparation_report_manifest.R"
reader_test_rel <- "tests/hypotheses/H08/test_h08_stage3_reader_report.R"
companion_test_rel <- "tests/hypotheses/H08/test_h08_preparation_report.R"

manifest <- read.csv(manifest_path, check.names = FALSE)
assert_true(nrow(manifest) == 258L, "Preparation manifest must contain 258 rows")
assert_true(!anyDuplicated(manifest$path), "Preparation manifest paths are not unique")
assert_true(!manifest_rel %in% manifest$path, "Preparation manifest contains itself")
assert_true(
  !any(grepl("report018_order55_companion_render", manifest$path, fixed = TRUE)),
  "Preparation manifest contains an order-55 evidence path"
)
manifest_files <- file.path(root, manifest$path)
manifest_exists <- file.exists(manifest_files) & !dir.exists(manifest_files)
manifest_sha <- rep(NA_character_, nrow(manifest))
manifest_bytes <- rep(NA_real_, nrow(manifest))
manifest_sha[manifest_exists] <- unname(vapply(
  manifest_files[manifest_exists], sha256_file, character(1)
))
manifest_bytes[manifest_exists] <- unname(file.info(
  manifest_files[manifest_exists]
)$size)
manifest_exact <- manifest_exists & manifest_sha == manifest$sha256 &
  manifest_bytes == as.numeric(manifest$bytes)
assert_all(manifest_exact, "A preparation manifest member is not live exact")
write_evidence(
  data.frame(
    path = manifest$path,
    role = manifest$role,
    sha256 = manifest$sha256,
    bytes = manifest$bytes,
    exists = manifest_exists,
    live_exact = manifest_exact,
    status = ifelse(manifest_exact, "PASS", "FAIL")
  ),
  "preparation_manifest_posthelper_audit.csv"
)

source_path <- file.path(root, source_rel)
build_source_path <- file.path(root, build_source_rel)
source_raw <- readBin(source_path, what = "raw", n = file_bytes(source_path))
build_source_raw <- readBin(
  build_source_path,
  what = "raw",
  n = file_bytes(build_source_path)
)
assert_true(identical(source_raw, build_source_raw), "Build QMD copy is not byte-identical")
assert_true(
  sha256_file(source_path) ==
    "3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d" &&
    sha256_file(build_source_path) ==
    "3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d",
  "Source or build QMD identity differs"
)
assert_true(
  sha256_file(file.path(root, helper_rel)) ==
    "55fb72225d86ae694778339f395c0bd23f1870ea587bff1a29741af729727014",
  "Helper changed during execution"
)
assert_true(
  sha256_file(file.path(root, reader_test_rel)) ==
    "3049ecd80bc7f6c83dce7370b2877a92c6693dd9585f1f45ed7ac19fdf64be8f" &&
    sha256_file(file.path(root, companion_test_rel)) ==
    "2e83542b120021e0c337a3769127e6eba2fe61ebc4d56014693b34066a3fc2a4",
  "A historical H08 test changed"
)
assert_true(
  !file.exists(file.path(root, "audit/hypotheses/H08/H08_analysis_preparation.html")),
  "Source-side companion HTML exists"
)

protected_pre <- read.csv(
  file.path(working_dir, "protected_inventory_prerender.csv"),
  check.names = FALSE
)
protected_files <- file.path(root, protected_pre$path)
protected_exists <- file.exists(protected_files) & !dir.exists(protected_files)
protected_sha <- rep(NA_character_, nrow(protected_pre))
protected_bytes <- rep(NA_real_, nrow(protected_pre))
protected_sha[protected_exists] <- unname(vapply(
  protected_files[protected_exists], sha256_file, character(1)
))
protected_bytes[protected_exists] <- unname(file.info(
  protected_files[protected_exists]
)$size)
protected_exact <- protected_exists & protected_sha == protected_pre$sha256 &
  protected_bytes == as.numeric(protected_pre$bytes)
changed_paths <- protected_pre$path[!protected_exact]
allowed_changed_paths <- c(
  build_source_rel,
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html",
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation_files/figure-html/fig-h08-prep-vlsq-distribution-1.png",
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation_files/figure-html/fig-h08-prep-sample-support-1.png",
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation_files/figure-html/fig-h08-prep-site-range-1.png",
  manifest_rel
)
assert_true(
  all(changed_paths %in% allowed_changed_paths) &&
    all(c(
      build_source_rel,
      "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html",
      manifest_rel
    ) %in% changed_paths),
  paste("Unexpected protected changes:", paste(changed_paths, collapse = ", "))
)
write_evidence(
  data.frame(
    path = protected_pre$path,
    before_sha256 = protected_pre$sha256,
    after_sha256 = protected_sha,
    before_bytes = protected_pre$bytes,
    after_bytes = protected_bytes,
    changed = !protected_exact,
    classification = ifelse(
      protected_pre$path == manifest_rel,
      "authorized truthful helper manifest",
      ifelse(
        protected_pre$path == build_source_rel,
        "authorized helper source-identical build QMD copy",
        ifelse(
          protected_pre$path ==
            "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html",
          "authorized companion render target",
          ifelse(
            grepl(
              "^_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation_files/figure-html/fig-h08-prep-.*-1[.]png$",
              protected_pre$path
            ),
            "authorized companion render target resource",
            "preserved"
          )
        )
      )
    ),
    status = ifelse(
      protected_exact | protected_pre$path %in% allowed_changed_paths,
      "PASS",
      "FAIL"
    )
  ),
  "helper_protected_reconciliation.csv"
)

helper_status <- data.frame(
  check = c(
    "helper executions",
    "manifest rows",
    "unique paths",
    "live-exact rows",
    "non-circular manifest",
    "order-55 evidence rows",
    "source and build QMD byte identity",
    "historical tests executed",
    "post-render and helper protected changes"
  ),
  observed = c(
    "1",
    nrow(manifest),
    length(unique(manifest$path)),
    sum(manifest_exact),
    sum(manifest$path == manifest_rel),
    sum(grepl("report018_order55_companion_render", manifest$path, fixed = TRUE)),
    identical(source_raw, build_source_raw),
    "0",
    paste(changed_paths, collapse = "|")
  ),
  expected = c(
    "1", "258", "258", "258", "0", "0", "TRUE", "0",
    paste(changed_paths, collapse = "|")
  ),
  status = "PASS"
)
write_evidence(helper_status, "helper_execution.csv")

cat(sprintf(
  paste0(
    "ORDER55_HELPER=PASS executions=1 manifest=%d/%d unique=%d ",
    "non_circular=TRUE evidence_rows=0 qmd_copy=BYTE_IDENTICAL ",
    "combined_changes=%d manifest_sha256=%s manifest_bytes=%d\n"
  ),
  sum(manifest_exact),
  nrow(manifest),
  length(unique(manifest$path)),
  length(changed_paths),
  sha256_file(manifest_path),
  file_bytes(manifest_path)
))
