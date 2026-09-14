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
write_csv <- function(object, filename) {
  write.csv(
    object,
    file.path(evidence_dir, filename),
    row.names = FALSE,
    na = ""
  )
}

old_manifest <- read.csv(
  file.path(evidence_dir, "H01_preparation_report_manifest.pre.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
new_manifest_path <-
  "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv"
new_manifest <- read.csv(
  new_manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(old_manifest) == 62L,
  nrow(new_manifest) == 65L,
  !anyDuplicated(old_manifest$path),
  !anyDuplicated(new_manifest$path),
  !any(new_manifest$path == new_manifest_path),
  all(file.exists(new_manifest$path)),
  all(!dir.exists(new_manifest$path))
)
new_manifest$current_sha256 <- vapply(
  new_manifest$path,
  artifact_sha256,
  character(1)
)
new_manifest$current_bytes <- as.numeric(file.info(new_manifest$path)$size)
new_manifest$live_exact <- new_manifest$sha256 == new_manifest$current_sha256 &
  new_manifest$bytes == new_manifest$current_bytes
stopifnot(all(new_manifest$live_exact))
write_csv(new_manifest, "order32j_preparation_manifest_post_helper_audit.csv")

added_paths <- setdiff(new_manifest$path, old_manifest$path)
removed_paths <- setdiff(old_manifest$path, new_manifest$path)
stopifnot(
  identical(
    sort(added_paths),
    sort(c(
      "scripts/hypotheses/H01/reconcile_h01_report016_deviations.R",
      "scripts/hypotheses/H01/refresh_h01_order32d_figures.R",
      paste0(
        "scripts/hypotheses/H01/",
        "refresh_h01_stage3_model_support_fdr_label.R"
      )
    ))
  ),
  length(removed_paths) == 0L
)
added <- new_manifest[new_manifest$path %in% added_paths, , drop = FALSE]
added$transition <- "ADDED_BY_EXISTING_DYNAMIC_SCRIPT_DISCOVERY"
write_csv(added, "order32j_unexpected_manifest_paths.csv")

common <- merge(
  old_manifest,
  new_manifest[, names(old_manifest), drop = FALSE],
  by = "path",
  suffixes = c("_before", "_after"),
  sort = FALSE
)
common_changed <- common[
  common$sha256_before != common$sha256_after |
    common$bytes_before != common$bytes_after,
  ,
  drop = FALSE
]
write_csv(common_changed, "order32j_manifest_common_row_changes.csv")

source_dir <- "artifacts/11_source_data/H01/preparation"
target_dir <- paste0(
  "_build/nathealth/audit/hypotheses/H01/",
  "H01_analysis_preparation_files/source-data"
)
download_names <- c(
  "H01_preparation_fitted_sample_support.csv",
  "H01_preparation_model_frame_retention.csv"
)
sources <- file.path(source_dir, download_names)
targets <- file.path(target_dir, download_names)
downloads <- data.frame(
  filename = download_names,
  source_path = sources,
  target_path = targets,
  source_sha256 = vapply(sources, artifact_sha256, character(1)),
  target_sha256 = vapply(targets, artifact_sha256, character(1)),
  source_bytes = as.numeric(file.info(sources)$size),
  target_bytes = as.numeric(file.info(targets)$size),
  target_regular = file_test("-f", targets),
  target_symlink = nzchar(Sys.readlink(targets)),
  stringsAsFactors = FALSE
)
downloads$exact <- downloads$source_sha256 == downloads$target_sha256 &
  downloads$source_bytes == downloads$target_bytes &
  downloads$target_regular & !downloads$target_symlink
stopifnot(all(downloads$exact))
write_csv(downloads, "order32j_download_audit_post_helper.csv")

identity_paths <- c(
  helper = "scripts/hypotheses/H01/build_h01_preparation_report_manifest.R",
  source_qmd = "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  build_qmd = paste0(
    "_build/nathealth/audit/hypotheses/H01/",
    "H01_analysis_preparation.qmd"
  ),
  companion_html = paste0(
    "_build/nathealth/audit/hypotheses/H01/",
    "H01_analysis_preparation.html"
  ),
  result_qmd = "notebooks/hypotheses/H01.qmd",
  result_html = "_build/nathealth/notebooks/hypotheses/H01.html",
  profile = "_quarto-nathealth.yml",
  preparation_manifest = new_manifest_path,
  worker_manifest = "artifacts/12_manifests/H01_worker_artifacts.csv"
)
identities <- data.frame(
  item = names(identity_paths),
  path = unname(identity_paths),
  sha256 = vapply(identity_paths, artifact_sha256, character(1)),
  bytes = as.numeric(file.info(identity_paths)$size),
  stringsAsFactors = FALSE
)
stopifnot(
  identities$sha256[identities$item == "source_qmd"] ==
    "ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f",
  identities$sha256[identities$item == "build_qmd"] ==
    identities$sha256[identities$item == "source_qmd"],
  identities$bytes[identities$item == "build_qmd"] ==
    identities$bytes[identities$item == "source_qmd"],
  identities$sha256[identities$item == "companion_html"] ==
    "5ab6587465f01f946fcf133f9f81a69168e08fa866f69830c2378e6c3cf250fe",
  identities$sha256[identities$item == "result_qmd"] ==
    "9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb",
  identities$sha256[identities$item == "result_html"] ==
    "df78ac3c2ed91515058b6af38e01b85b4baae74118699c008a29ba4dacf4d007",
  identities$sha256[identities$item == "profile"] ==
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  identities$sha256[identities$item == "worker_manifest"] ==
    "882c1e63290384723b47d1bf67eb524c6a18e21d710eb60c989067bfe08c387c"
)
write_csv(identities, "order32j_current_identities_at_stop.csv")

protected_pre <- read.csv(
  file.path(evidence_dir, "order32j_protected_inventory_pre.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
protected_post <- protected_pre[, c("path", "sha256", "bytes"), drop = FALSE]
names(protected_post)[2:3] <- c("sha256_before", "bytes_before")
protected_post$sha256_after <- vapply(
  protected_post$path,
  artifact_sha256,
  character(1)
)
protected_post$bytes_after <- as.numeric(file.info(protected_post$path)$size)
protected_post$changed <- protected_post$sha256_before !=
  protected_post$sha256_after |
  protected_post$bytes_before != protected_post$bytes_after
protected_changes <- protected_post[protected_post$changed, , drop = FALSE]
expected_protected_changes <- c(
  "scripts/hypotheses/H01/build_h01_preparation_report_manifest.R",
  paste0(
    "_build/nathealth/audit/hypotheses/H01/",
    "H01_analysis_preparation.qmd"
  ),
  new_manifest_path
)
stopifnot(identical(
  sort(protected_changes$path),
  sort(expected_protected_changes)
))
write_csv(protected_post, "order32j_protected_comparison_at_stop.csv")

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
build_post <- data.frame(
  path = paths,
  type = types,
  sha256 = NA_character_,
  bytes = NA_real_,
  stringsAsFactors = FALSE
)
is_file <- build_post$type == "file"
build_post$sha256[is_file] <- vapply(
  entries[is_file],
  artifact_sha256,
  character(1)
)
build_post$bytes[is_file] <- as.numeric(file.info(entries[is_file])$size)
build_post <- build_post[order(build_post$path), , drop = FALSE]
write_csv(build_post, "order32j_build_inventory_at_stop.csv")

build_added <- build_post[!build_post$path %in% build_pre$path, , drop = FALSE]
build_removed <- build_pre[!build_pre$path %in% build_post$path, , drop = FALSE]
build_common <- merge(
  build_pre[, c("path", "type", "sha256", "bytes")],
  build_post,
  by = "path",
  suffixes = c("_before", "_after"),
  sort = FALSE
)
normal <- function(value) {
  value[is.na(value) | value == ""] <- NA_character_
  value
}
before_sha <- normal(build_common$sha256_before)
after_sha <- normal(build_common$sha256_after)
same_sha <- ifelse(
  is.na(before_sha) & is.na(after_sha),
  TRUE,
  ifelse(is.na(before_sha) | is.na(after_sha), FALSE, before_sha == after_sha)
)
same_bytes <- ifelse(
  is.na(build_common$bytes_before) & is.na(build_common$bytes_after),
  TRUE,
  ifelse(
    is.na(build_common$bytes_before) | is.na(build_common$bytes_after),
    FALSE,
    build_common$bytes_before == build_common$bytes_after
  )
)
build_common$changed <- build_common$type_before != build_common$type_after |
  !same_sha | !same_bytes
build_common_changed <- build_common[build_common$changed, , drop = FALSE]
write_csv(build_added, "order32j_build_added_at_stop.csv")
write_csv(build_removed, "order32j_build_removed_at_stop.csv")
write_csv(build_common_changed, "order32j_build_changed_at_stop.csv")

summary <- data.frame(
  requirement = c(
    "helper_execution_count",
    "preparation_manifest_required_rows",
    "preparation_manifest_observed_rows",
    "preparation_manifest_live_exact",
    "unexpected_manifest_paths",
    "removed_manifest_paths",
    "downloads_exact",
    "build_qmd_source_exact",
    "companion_html_preserved",
    "worker_manifest_preserved_without_reseal",
    "protected_changes_confined_to_authorized_mutations",
    "status"
  ),
  value = c(
    "1",
    "62",
    as.character(nrow(new_manifest)),
    sprintf("%d/%d", sum(new_manifest$live_exact), nrow(new_manifest)),
    as.character(length(added_paths)),
    as.character(length(removed_paths)),
    sprintf("%d/%d", sum(downloads$exact), nrow(downloads)),
    "TRUE",
    "TRUE",
    "TRUE",
    "TRUE",
    "STOPPED_NEW_MANIFEST_CARDINALITY_DEFECT"
  ),
  stringsAsFactors = FALSE
)
write_csv(summary, "order32j_stopped_summary.csv")
cat(
  sprintf(
    paste0(
      "order32j=STOP manifest=%d required=62 exact=%d/%d ",
      "unexpected=%d protected_changes=%d\n"
    ),
    nrow(new_manifest),
    sum(new_manifest$live_exact),
    nrow(new_manifest),
    length(added_paths),
    nrow(protected_changes)
  )
)
