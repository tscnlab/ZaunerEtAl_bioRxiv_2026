#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, args[[1L]] %in% c("previsual", "postvisual"))
phase <- args[[1L]]

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))
stopifnot(identical(as.character(getRversion()), "4.6.1"))

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H02/report017_order33g_result_completion"
)
build_root <- normalizePath(
  file.path(root, "_build/nathealth"),
  winslash = "/",
  mustWork = TRUE
)

write_csv <- function(object, filename) {
  utils::write.csv(
    object,
    file.path(evidence_dir, filename),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

hash_file <- function(path) {
  if (!file.exists(path) || dir.exists(path) || nzchar(Sys.readlink(path))) {
    return(NA_character_)
  }
  artifact_sha256(path)
}

format_mtime <- function(value) {
  format(
    as.POSIXct(value, origin = "1970-01-01", tz = "UTC"),
    "%Y-%m-%d %H:%M:%OS6 %Z",
    tz = "UTC"
  )
}

# Dispatch reconciliation with the sole authorized reader-test transition.
dispatch <- utils::read.csv(
  "audit/report_harmonization/report017_h02_order33g_dispatch_manifest.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(nrow(dispatch) == 42L, !anyDuplicated(dispatch$path))
dispatch_paths <- ifelse(
  startsWith(dispatch$path, "/"),
  dispatch$path,
  file.path(root, dispatch$path)
)
dispatch$current_sha256 <- vapply(dispatch_paths, hash_file, character(1))
dispatch$current_bytes <- as.numeric(file.info(dispatch_paths)$size)
dispatch$pre_dispatch_exact <- dispatch$current_sha256 == dispatch$sha256 &
  dispatch$current_bytes == dispatch$bytes
dispatch$authorized_reader_transition <-
  dispatch$role == "reader_test_mutation_target" &
  dispatch$current_sha256 ==
    "479a702e7c5c52cf85e8591300a30c759da945f4c65ecb28cad67bb2e6752d3f" &
  dispatch$current_bytes == 16545
dispatch$pass <- dispatch$pre_dispatch_exact |
  dispatch$authorized_reader_transition
write_csv(dispatch, paste0("dispatch_reconciliation_", phase, ".csv"))

# Current accepted-path inventory, anchored to the order-33f post-QA inventory.
accepted_baseline <- utils::read.csv(
  "audit/hypotheses/H02/report017_order33f_result_render/accepted_inventory_postqa.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
accepted_paths <- file.path(root, accepted_baseline$path)
accepted_current <- accepted_baseline
accepted_current$exists <- file.exists(accepted_paths)
accepted_current$sha256 <- vapply(accepted_paths, hash_file, character(1))
accepted_current$bytes <- as.numeric(file.info(accepted_paths)$size)
accepted_current$mtime_utc <- format_mtime(file.info(accepted_paths)$mtime)
accepted_current$baseline_byte_exact <-
  accepted_current$exists &
  accepted_current$sha256 == accepted_baseline$sha256 &
  accepted_current$bytes == accepted_baseline$bytes
accepted_current$authorized_reader_transition <-
  accepted_current$path == "tests/hypotheses/H02/test_h02_reader_report.R" &
  accepted_current$sha256 ==
    "479a702e7c5c52cf85e8591300a30c759da945f4c65ecb28cad67bb2e6752d3f" &
  accepted_current$bytes == 16545
accepted_current$authorized_coordination_baseline <-
  accepted_current$path ==
    "audit/report_harmonization/coordination_matrix.csv" &
  accepted_current$sha256 ==
    "15bb2b01a2e7fa9057693e2a991f8593c4a20679ca7b68cdb90ac6b36677cacf" &
  accepted_current$bytes == 25614
accepted_current$pass <- accepted_current$baseline_byte_exact |
  accepted_current$authorized_reader_transition |
  accepted_current$authorized_coordination_baseline
write_csv(
  accepted_current,
  paste0("accepted_inventory_", phase, ".csv")
)

# Complete build inventory and symlink safety.
entries <- c(
  build_root,
  list.files(
    build_root,
    full.names = TRUE,
    recursive = TRUE,
    all.files = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  )
)
entries <- sort(unique(entries))
links <- Sys.readlink(entries)
is_link <- nzchar(links)
is_directory <- dir.exists(entries) & !is_link
is_file <- file.exists(entries) & !dir.exists(entries) & !is_link
info <- file.info(entries)
relative <- ifelse(
  entries == build_root,
  "",
  substring(entries, nchar(build_root) + 2L)
)
link_resolved <- rep("", length(entries))
link_safe <- rep(NA, length(entries))
if (any(is_link)) {
  for (index in which(is_link)) {
    candidate <- if (startsWith(links[[index]], "/")) {
      links[[index]]
    } else {
      file.path(dirname(entries[[index]]), links[[index]])
    }
    resolved <- normalizePath(candidate, winslash = "/", mustWork = TRUE)
    link_resolved[[index]] <- resolved
    link_safe[[index]] <- identical(resolved, build_root) ||
      startsWith(resolved, paste0(build_root, "/"))
  }
}
sha256 <- rep("", length(entries))
sha256[is_file] <- vapply(entries[is_file], artifact_sha256, character(1))
bytes <- rep(NA_real_, length(entries))
bytes[is_file] <- as.numeric(info$size[is_file])
build <- data.frame(
  path = relative,
  type = ifelse(is_link, "symlink", ifelse(is_directory, "directory", "file")),
  sha256 = sha256,
  bytes = bytes,
  mtime_utc = format_mtime(info$mtime),
  mode = sprintf("%04o", as.integer(info$mode)),
  link_target = links,
  link_resolved = link_resolved,
  link_safe = link_safe,
  stringsAsFactors = FALSE
)
build <- build[order(build$path), , drop = FALSE]
row.names(build) <- NULL
write_csv(build, paste0("build_inventory_", phase, ".csv"))
write_csv(
  build[build$type == "symlink", , drop = FALSE],
  paste0("build_symlink_inventory_", phase, ".csv")
)

baseline_build <- utils::read.csv(
  "audit/hypotheses/H02/report017_order33f_result_render/build_inventory_postqa.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
build_baseline_path <-
  "audit/hypotheses/H02/report017_order33f_result_render/build_inventory_postqa.csv"
build_current_path <- file.path(
  evidence_dir,
  paste0("build_inventory_", phase, ".csv")
)
build_baseline_exact <-
  artifact_sha256(build_current_path) == artifact_sha256(build_baseline_path)
build_comparison <- data.frame(
  comparison = "current build versus accepted order-33f post-QA build",
  baseline_rows = nrow(baseline_build),
  current_rows = nrow(build),
  byte_and_metadata_identical = build_baseline_exact,
  symlinks = sum(build$type == "symlink"),
  unsafe_symlinks = sum(build$type == "symlink" & !build$link_safe, na.rm = TRUE),
  pass = build_baseline_exact &&
    !any(build$type == "symlink" & !build$link_safe, na.rm = TRUE),
  stringsAsFactors = FALSE
)
write_csv(
  build_comparison,
  paste0("build_baseline_comparison_", phase, ".csv")
)

# Deferred companion preparation-manifest state.
preparation_manifest_path <-
  "artifacts/12_manifests/H02/H02_preparation_report_manifest.csv"
preparation_manifest <- utils::read.csv(
  preparation_manifest_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
preparation_paths <- file.path(root, preparation_manifest$path)
preparation_exists <- file.exists(preparation_paths)
preparation_current_sha <- rep(NA_character_, length(preparation_paths))
preparation_current_bytes <- rep(NA_real_, length(preparation_paths))
preparation_current_sha[preparation_exists] <- vapply(
  preparation_paths[preparation_exists],
  artifact_sha256,
  character(1)
)
preparation_current_bytes[preparation_exists] <-
  as.numeric(file.info(preparation_paths[preparation_exists])$size)
preparation_mismatch <- preparation_manifest$path[
  !preparation_exists |
    preparation_current_sha != preparation_manifest$sha256 |
    preparation_current_bytes != preparation_manifest$bytes
]
expected_preparation_mismatch <- sort(c(
  "_build/nathealth/notebooks/hypotheses/H02.html",
  "_quarto-nathealth.yml",
  "audit/hypotheses/H02/H02_analysis_preparation.qmd",
  "notebooks/hypotheses/H02.qmd"
))
preparation_state <- data.frame(
  expected_mismatches = paste(expected_preparation_mismatch, collapse = " | "),
  current_mismatches = paste(sort(preparation_mismatch), collapse = " | "),
  mismatch_count = length(preparation_mismatch),
  held_preparation_test_sha256 = artifact_sha256(
    "tests/hypotheses/H02/test_h02_preparation_report.R"
  ),
  held_companion_qmd_sha256 = artifact_sha256(
    "audit/hypotheses/H02/H02_analysis_preparation.qmd"
  ),
  held_companion_html_sha256 = artifact_sha256(
    "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html"
  ),
  pass = identical(sort(preparation_mismatch), expected_preparation_mismatch) &&
    artifact_sha256("tests/hypotheses/H02/test_h02_preparation_report.R") ==
      "ead7a55246a2625b1382acc302b6004892dbf7f7830285f2bae830cb0859d3f8" &&
    artifact_sha256("audit/hypotheses/H02/H02_analysis_preparation.qmd") ==
      "92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1" &&
    artifact_sha256("_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html") ==
      "d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa",
  stringsAsFactors = FALSE
)
write_csv(
  preparation_state,
  paste0("held_companion_state_", phase, ".csv")
)

versions <- data.frame(
  component = "R",
  version = as.character(getRversion()),
  stringsAsFactors = FALSE
)
write_csv(versions, paste0("versions_", phase, ".csv"))

if (phase == "postvisual") {
  accepted_pre <- utils::read.csv(
    file.path(evidence_dir, "accepted_inventory_previsual.csv"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  build_pre <- utils::read.csv(
    file.path(evidence_dir, "build_inventory_previsual.csv"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  stability <- data.frame(
    inventory = c("accepted", "build"),
    rows_pre = c(nrow(accepted_pre), nrow(build_pre)),
    rows_post = c(nrow(accepted_current), nrow(build)),
    identical = c(
      artifact_sha256(file.path(evidence_dir, "accepted_inventory_postvisual.csv")) ==
        artifact_sha256(file.path(evidence_dir, "accepted_inventory_previsual.csv")),
      artifact_sha256(file.path(evidence_dir, "build_inventory_postvisual.csv")) ==
        artifact_sha256(file.path(evidence_dir, "build_inventory_previsual.csv"))
    ),
    stringsAsFactors = FALSE
  )
  write_csv(stability, "postvisual_inventory_stability.csv")
  stopifnot(all(stability$identical))
}

stopifnot(
  all(dispatch$pass),
  sum(dispatch$authorized_reader_transition) == 1L,
  all(accepted_current$pass),
  sum(accepted_current$authorized_reader_transition) == 1L,
  sum(accepted_current$authorized_coordination_baseline) == 1L,
  build_comparison$pass,
  preparation_state$pass
)

cat(sprintf(
  paste0(
    "phase=%s dispatch=%d/%d accepted=%d/%d build=%d symlinks=%d ",
    "preparation_mismatches=%d\n"
  ),
  phase,
  sum(dispatch$pass),
  nrow(dispatch),
  sum(accepted_current$pass),
  nrow(accepted_current),
  nrow(build),
  sum(build$type == "symlink"),
  preparation_state$mismatch_count
))
