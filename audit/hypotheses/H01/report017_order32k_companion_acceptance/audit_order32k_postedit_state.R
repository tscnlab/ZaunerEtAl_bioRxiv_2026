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
  "audit/hypotheses/H01/report017_order32k_companion_acceptance"
)
write_csv <- function(object, filename) {
  write.csv(
    object,
    file.path(evidence_dir, filename),
    row.names = FALSE,
    na = ""
  )
}
format_time <- function(value) {
  format(value, "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC")
}

manifest_path <-
  "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv"
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
manifest$current_sha256 <- vapply(manifest$path, artifact_sha256, character(1))
manifest$current_bytes <- as.numeric(file.info(manifest$path)$size)
manifest$live_exact <- manifest$sha256 == manifest$current_sha256 &
  manifest$bytes == manifest$current_bytes
stopifnot(
  artifact_sha256(manifest_path) ==
    "310a017f49992e8a4a17f8497b66112b8352364ef80526c11709c1f39155653e",
  nrow(manifest) == 65L,
  !anyDuplicated(manifest$path),
  !any(manifest$path == manifest_path),
  all(manifest$live_exact)
)
write_csv(manifest, "order32k_preparation_manifest_audit_post.csv")

worker_path <- "artifacts/12_manifests/H01_worker_artifacts.csv"
worker <- read.csv(worker_path, stringsAsFactors = FALSE, check.names = FALSE)
exists <- file.exists(worker$path) & !dir.exists(worker$path)
current_sha <- rep(NA_character_, nrow(worker))
current_bytes <- rep(NA_real_, nrow(worker))
current_sha[exists] <- vapply(worker$path[exists], artifact_sha256, character(1))
current_bytes[exists] <- as.numeric(file.info(worker$path[exists])$size)
mismatch <- !exists | worker$sha256 != current_sha | worker$bytes != current_bytes
historical <- c(
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "_quarto-nathealth.yml"
)
stopifnot(
  nrow(worker) == 1659L,
  !anyDuplicated(worker$path),
  !any(worker$path == worker_path),
  identical(sort(worker$path[mismatch]), sort(historical))
)
worker_audit <- data.frame(
  path = worker$path,
  expected_sha256 = worker$sha256,
  current_sha256 = current_sha,
  expected_bytes = worker$bytes,
  current_bytes = current_bytes,
  status = ifelse(mismatch, "ACCEPTED_HISTORICAL_TRANSITION", "PASS_LIVE_EXACT"),
  stringsAsFactors = FALSE
)
write_csv(worker_audit, "order32k_worker_manifest_audit_post.csv")

pre_protected <- read.csv(
  file.path(evidence_dir, "order32k_protected_inventory_pre.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(all(file.exists(pre_protected$path)), all(!dir.exists(pre_protected$path)))
post_info <- file.info(pre_protected$path)
post_protected <- data.frame(
  path = pre_protected$path,
  sha256 = vapply(pre_protected$path, artifact_sha256, character(1)),
  bytes = as.numeric(post_info$size),
  mtime_utc = format_time(post_info$mtime),
  mode = sprintf("%04o", as.integer(post_info$mode)),
  stringsAsFactors = FALSE
)
write_csv(post_protected, "order32k_protected_inventory_postedit.csv")
protected <- merge(
  pre_protected,
  post_protected,
  by = "path",
  suffixes = c("_pre", "_post"),
  sort = FALSE
)
protected$content_identical <- protected$sha256_pre == protected$sha256_post &
  protected$bytes_pre == protected$bytes_post
expected_changes <- c(
  "tests/hypotheses/H01/test_h01_preparation_report.R",
  worker_path
)
mutable_coordination_evidence <-
  "audit/report_harmonization/coordination_matrix.csv"
external_order35b_changes <- c(
  "notebooks/hypotheses/H04.qmd",
  "audit/hypotheses/H04/H04_analysis_preparation.qmd"
)
protected$classification <- ifelse(
  protected$content_identical,
  "PASS_IDENTICAL",
  ifelse(
    protected$path %in% expected_changes,
    "AUTHORIZED_ORDER32K_CHANGE",
    ifelse(
      protected$path == mutable_coordination_evidence,
      "ALLOWED_MUTABLE_COORDINATION_EVIDENCE",
      ifelse(
        protected$path %in% external_order35b_changes,
        "EXTERNAL_ORDER35B_POST_FINDING_TRANSITION",
        "FAIL_UNEXPECTED_DRIFT"
      )
    )
  )
)
h04_reverse_path <- paste0(
  "audit/hypotheses/H04/report017_order35b_country_label_reflow/",
  "H04_order35b_qmd_reverse_proof.csv"
)
h04_reverse <- read.csv(
  h04_reverse_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
h04_pre <- pre_protected[
  match(external_order35b_changes, pre_protected$path),
  c("path", "sha256", "bytes"),
  drop = FALSE
]
h04_post <- post_protected[
  match(external_order35b_changes, post_protected$path),
  c("path", "sha256", "bytes"),
  drop = FALSE
]
stopifnot(
  identical(
    sort(protected$path[protected$classification == "AUTHORIZED_ORDER32K_CHANGE"]),
    sort(expected_changes)
  ),
  identical(
  protected$path[
      protected$classification == "ALLOWED_MUTABLE_COORDINATION_EVIDENCE"
    ],
    mutable_coordination_evidence
  ),
  identical(
    sort(protected$path[
      protected$classification ==
        "EXTERNAL_ORDER35B_POST_FINDING_TRANSITION"
    ]),
    sort(external_order35b_changes)
  ),
  identical(h04_pre$path, external_order35b_changes),
  identical(h04_post$path, external_order35b_changes),
  identical(h04_reverse$source, external_order35b_changes),
  identical(h04_reverse$pre_sha256, h04_pre$sha256),
  identical(as.numeric(h04_reverse$pre_bytes), as.numeric(h04_pre$bytes)),
  identical(h04_reverse$current_sha256, h04_post$sha256),
  identical(
    as.numeric(h04_reverse$current_bytes),
    as.numeric(h04_post$bytes)
  ),
  all(h04_reverse$reverse_status == "PASS"),
  !any(protected$classification == "FAIL_UNEXPECTED_DRIFT")
)
write_csv(protected, "order32k_protected_reconciliation_postedit.csv")

pre_build <- read.csv(
  file.path(evidence_dir, "order32k_build_inventory_pre.csv"),
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
is_link <- nzchar(links)
types <- ifelse(is_link, "symlink", ifelse(dir.exists(entries), "directory", "file"))
relative <- ifelse(entries == build_root, "", substring(entries, nchar(build_root) + 2L))
resolved <- rep("", length(entries))
safe <- rep(NA, length(entries))
if (any(is_link)) {
  for (index in which(is_link)) {
    candidate <- if (startsWith(links[[index]], "/")) {
      links[[index]]
    } else {
      file.path(dirname(entries[[index]]), links[[index]])
    }
    resolved[[index]] <- normalizePath(candidate, winslash = "/", mustWork = TRUE)
    safe[[index]] <- identical(resolved[[index]], build_root) ||
      startsWith(resolved[[index]], paste0(build_root, "/"))
  }
  stopifnot(all(safe[is_link]))
}
entry_info <- file.info(entries)
sha256 <- rep(NA_character_, length(entries))
bytes <- rep(NA_real_, length(entries))
is_file <- types == "file"
sha256[is_file] <- vapply(entries[is_file], artifact_sha256, character(1))
bytes[is_file] <- as.numeric(entry_info$size[is_file])
post_build <- data.frame(
  path = relative,
  type = types,
  sha256 = sha256,
  bytes = bytes,
  mtime_utc = format_time(entry_info$mtime),
  mode = sprintf("%04o", as.integer(entry_info$mode)),
  link_target = links,
  link_resolved = resolved,
  link_safe = safe,
  stringsAsFactors = FALSE
)
post_build <- post_build[order(post_build$path), , drop = FALSE]
write_csv(post_build, "order32k_build_inventory_postedit.csv")

normal_character <- function(value) {
  value[is.na(value) | value == ""] <- NA_character_
  value
}
same_character <- function(before, after) {
  before <- normal_character(before)
  after <- normal_character(after)
  ifelse(
    is.na(before) & is.na(after),
    TRUE,
    ifelse(is.na(before) | is.na(after), FALSE, before == after)
  )
}
same_numeric <- function(before, after) {
  ifelse(
    is.na(before) & is.na(after),
    TRUE,
    ifelse(is.na(before) | is.na(after), FALSE, before == after)
  )
}
stopifnot(
  identical(post_build$path, pre_build$path),
  identical(post_build$type, pre_build$type),
  all(same_character(post_build$sha256, pre_build$sha256)),
  all(same_numeric(post_build$bytes, pre_build$bytes)),
  sum(post_build$type == "symlink") == 0L
)
build_comparison <- data.frame(
  path = pre_build$path,
  type = pre_build$type,
  sha256_pre = pre_build$sha256,
  sha256_post = post_build$sha256,
  bytes_pre = pre_build$bytes,
  bytes_post = post_build$bytes,
  content_identical = same_character(pre_build$sha256, post_build$sha256) &
    same_numeric(pre_build$bytes, post_build$bytes),
  stringsAsFactors = FALSE
)
write_csv(build_comparison, "order32k_build_reconciliation_postedit.csv")

html_contracts <- read.csv(
  file.path(evidence_dir, "order32k_html_contracts.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
headers <- read.csv(
  file.path(evidence_dir, "order32k_header_resolution_audit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
idrefs <- read.csv(
  file.path(evidence_dir, "order32k_idref_resolution_audit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
tables <- read.csv(
  file.path(evidence_dir, "order32k_table_endpoint_audit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
figures <- read.csv(
  file.path(evidence_dir, "order32k_figure_endpoint_audit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
country <- read.csv(
  file.path(evidence_dir, "order32k_country_site_audit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
h04_findings <- read.csv(
  file.path(evidence_dir, "order32k_h04_global_country_findings.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  all(html_contracts$pass),
  nrow(tables) == 20L,
  nrow(figures) == 2L,
  nrow(headers) == 1442L,
  all(headers$pass),
  nrow(idrefs) == 1471L,
  all(idrefs$pass),
  nrow(country) == 9L,
  all(country$present),
  nrow(h04_findings) == 2L,
  identical(h04_findings$path, c(
    "notebooks/hypotheses/H04.qmd",
    "audit/hypotheses/H04/H04_analysis_preparation.qmd"
  )),
  identical(h04_findings$line, c(886L, 914L))
)

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
  preparation_manifest = manifest_path,
  preparation_test = "tests/hypotheses/H01/test_h01_preparation_report.R",
  worker_manifest = worker_path
)
identities <- data.frame(
  item = names(identity_paths),
  path = unname(identity_paths),
  sha256 = vapply(identity_paths, artifact_sha256, character(1)),
  bytes = as.numeric(file.info(identity_paths)$size),
  stringsAsFactors = FALSE
)
stopifnot(
  identities$sha256[identities$item == "helper"] ==
    "da6e5c743d8eb693b35453b7a67344fb012344144697d2d0c0b94a0d91cbdcbf",
  identities$sha256[identities$item == "source_qmd"] ==
    "ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f",
  identities$sha256[identities$item == "build_qmd"] ==
    identities$sha256[identities$item == "source_qmd"],
  identities$sha256[identities$item == "companion_html"] ==
    "5ab6587465f01f946fcf133f9f81a69168e08fa866f69830c2378e6c3cf250fe",
  identities$sha256[identities$item == "result_qmd"] ==
    "9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb",
  identities$sha256[identities$item == "result_html"] ==
    "df78ac3c2ed91515058b6af38e01b85b4baae74118699c008a29ba4dacf4d007",
  identities$sha256[identities$item == "profile"] ==
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  identities$sha256[identities$item == "preparation_manifest"] ==
    "310a017f49992e8a4a17f8497b66112b8352364ef80526c11709c1f39155653e"
)
write_csv(identities, "order32k_key_identities_postedit.csv")

summary <- data.frame(
  check = c(
    "preparation_manifest",
    "worker_manifest",
    "protected_inventory",
    "build_inventory",
    "semantic_contracts",
    "gt_tables",
    "figures",
    "headers",
    "supported_idrefs",
    "h01_country_sites",
    "h04_expected_findings"
  ),
  evidence = c(
    "65/65 live-exact",
    sprintf("%d/%d live-exact; 2 historical", sum(!mismatch), nrow(worker)),
    sprintf(
      paste0(
        "%d paths; 2 authorized H01 changes; 1 mutable coordination ",
        "record; 2 independently sealed H04 order-35b whitespace reflows"
      ),
      nrow(protected)
    ),
    sprintf("%d/%d content-identical", sum(build_comparison$content_identical), nrow(build_comparison)),
    sprintf("%d/%d", sum(html_contracts$pass), nrow(html_contracts)),
    as.character(nrow(tables)),
    as.character(nrow(figures)),
    as.character(nrow(headers)),
    as.character(nrow(idrefs)),
    sprintf("%d/%d", sum(country$present), nrow(country)),
    as.character(nrow(h04_findings))
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
write_csv(summary, "order32k_postedit_summary.csv")
cat(sprintf(
  paste0(
    "postedit=PASS manifest=65/65 worker=%d/%d protected=%d ",
    "build=%d/%d semantic=%d/%d headers=%d idrefs=%d H04=%d\n"
  ),
  sum(!mismatch),
  nrow(worker),
  nrow(protected),
  sum(build_comparison$content_identical),
  nrow(build_comparison),
  sum(html_contracts$pass),
  nrow(html_contracts),
  nrow(headers),
  nrow(idrefs),
  nrow(h04_findings)
))
