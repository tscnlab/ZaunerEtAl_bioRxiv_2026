#!/usr/bin/env Rscript

Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE, warn = 2, lifecycle_verbosity = "quiet")

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 57c fail-closed verification requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(tibble)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT"),
  winslash = "/",
  mustWork = TRUE
)
working_dir <- normalizePath(
  Sys.getenv("ORDER57C_WORKING_DIR"),
  winslash = "/",
  mustWork = TRUE
)
semantic_dir <- normalizePath(
  Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
  winslash = "/",
  mustWork = TRUE
)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H09/report018_order57c_companion_retry"
)
stopifnot(
  dir.exists(evidence_dir),
  !startsWith(working_dir, paste0(root, "/")),
  !startsWith(semantic_dir, paste0(root, "/"))
)
setwd(root)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

sha256_raw <- function(value) {
  digest::digest(value, algo = "sha256", serialize = FALSE)
}

file_bytes <- function(path) unname(file.info(path)$size)

read_raw_file <- function(path) {
  readBin(path, what = "raw", n = file_bytes(path))
}

write_evidence <- function(value, name) {
  utils::write.csv(
    value,
    file.path(evidence_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

checks <- tibble::tibble(
  domain = character(),
  check = character(),
  observed = character(),
  expected = character(),
  contract_status = character(),
  evidence_status = character()
)

add_check <- function(
  domain,
  check,
  observed,
  expected,
  contract_status,
  evidence_pass
) {
  checks <<- bind_rows(
    checks,
    tibble::tibble(
      domain = domain,
      check = check,
      observed = paste(observed, collapse = "/"),
      expected = paste(expected, collapse = "/"),
      contract_status = contract_status,
      evidence_status = if (isTRUE(evidence_pass)) "PASS" else "FAIL"
    )
  )
}

pins <- tibble::tribble(
  ~path, ~sha256, ~bytes, ~role,
  "audit/report_harmonization/owner_orders/57c_h09_environment_process_probe_and_companion_retry.md",
  "8aa2087907c2108f6235394dfadb61b1eca1fbf0e2bd5a320f0eff71c859ea22",
  9750,
  "controlling order",
  "audit/report_harmonization/report018_h09_order57b_environment_stop_independent_acceptance.md",
  "1285402d9b1a18a4c4c6d7e96884bee077d66c309d21b686381b92aa7f744749",
  5205,
  "independent acceptance",
  "audit/report_harmonization/report018_h09_order57b_environment_stop_independent_acceptance_manifest.csv",
  "ed18bfce23bd13de72a7f3f9ec253ee0732b1c9942ce32196bb5d45cd9632f85",
  5161,
  "29-row acceptance seal",
  "audit/report_harmonization/report018_h09_order57c_dispatch_manifest.csv",
  "fd0661c7b66d7ff70004f5fcbc06f1c31597922c2a396bf7461245d8aa86bb6d",
  5600,
  "31-row dispatch",
  "scripts/report_harmonization/check_report018_h09_order57b_environment_stop.R",
  "9a5cd08e47e647f1fe269f0e1f170ffced6d81defc58244af451a63f4e79a937",
  12243,
  "independent environment checker",
  "audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "394a976e52faf002cb2034a13353a053aae8bfda8942a79c2eb007017cae014f",
  51736,
  "unchanged companion source",
  "notebooks/hypotheses/H09.qmd",
  "c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6",
  36970,
  "accepted result source",
  "_build/nathealth/notebooks/hypotheses/H09.html",
  "901fd63b45182be70ef77166c418633220a7226d86f52e14d1c79afbfc7cdd16",
  244127,
  "accepted result HTML",
  "artifacts/12_manifests/H09/H09_stage3_artifacts.csv",
  "0103aad8bf3b2424358fc139b85b95564054745b180a80d1e12c27ff72e1bef2",
  24678,
  "immutable Stage 3 manifest",
  "scripts/hypotheses/H09/h09_contract.R",
  "866b0f8736c8a25f50a3f1ce6e38c5d33d4666d4bf06031f0021ee1cb6d0b701",
  16374,
  "H09 contract",
  "artifacts/06_model_data/H09/H09_input_audit.csv",
  "1ea3910539378434533dcaeeaee6ab613e325468d99ffd10e02bdc868a4175ed",
  4401,
  "H09 input audit",
  "scripts/hypotheses/H09/build_h09_preparation_report_manifest.R",
  "c7a320367e0115aee221a3a6ba5228a9a27ba55f734bd07881455b3159cebf56",
  9753,
  "unchanged dedicated helper",
  "tests/hypotheses/H09/test_h09_preparation_report.R",
  "9a243e391de7069179fcd0ccb7cc6813a5e779b1ae1bf7fcb52706349553dfe7",
  12824,
  "unexecuted historical test",
  "_quarto-nathealth.yml",
  "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  7480,
  "accepted profile",
  "renv.lock",
  "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
  603493,
  "accepted lockfile"
)
pin_files <- file.path(root, pins$path)
pins <- pins |>
  mutate(
    observed_sha256 = vapply(pin_files, sha256_file, character(1)),
    observed_bytes = file_bytes(pin_files),
    exact = .data$observed_sha256 == .data$sha256 &
      .data$observed_bytes == .data$bytes,
    status = if_else(.data$exact, "PASS", "FAIL")
  )
stopifnot(nrow(pins) == 15L, all(pins$status == "PASS"))
write_evidence(pins, "controlling_and_preservation_pins.csv")
add_check(
  "authority and preservation",
  "controlling and unchanged scientific identities",
  paste0(sum(pins$exact), "/15"),
  "15/15",
  "PASS",
  all(pins$exact)
)

pre_verification <- utils::read.csv(
  file.path(working_dir, "verification_pre.csv"),
  check.names = FALSE
)
pre_process <- utils::read.csv(
  file.path(working_dir, "process_audit_pre.csv"),
  check.names = FALSE
)
pre_versions <- utils::read.csv(
  file.path(working_dir, "versions_pre.csv"),
  check.names = FALSE
)
copied_verifier <- file.path(working_dir, "verify_order57b_h09_companion.R")
stopifnot(
  sha256_file(copied_verifier) ==
    "a6c418c70216227dd335e7de850c119db13f7bfda7f0340f88c7d81f0ecc99fa",
  file_bytes(copied_verifier) == 37584,
  nrow(pre_verification) == 12L,
  all(pre_verification$status == "PASS"),
  nrow(pre_process) == 1L,
  pre_process$observed == "none",
  pre_process$competing_processes == 0L,
  pre_process$status == "PASS",
  identical(pre_versions$observed, c("4.6.1", "1.9.37")),
  all(pre_versions$status == "PASS")
)
write_evidence(pre_verification, "owner_pre_verification.csv")
write_evidence(pre_process, "owner_pre_process_inventory.csv")
add_check(
  "pre-render gate",
  "unchanged owner verifier and empty process inventory",
  paste(nrow(pre_verification), pre_process$competing_processes, sep = "/"),
  "12/0",
  "PASS",
  all(pre_verification$status == "PASS") &&
    pre_process$competing_processes == 0L
)

invocations <- tibble::tribble(
  ~phase, ~invocation_count, ~exit_code, ~status, ~detail,
  "order-57c owner pre-render verifier", 1L, 0L, "PASS", "Complete expected pre-mode line and zero competing processes",
  "H09 companion Quarto render", 1L, 0L, "PASS", "Single target render and semantic hook completed",
  "dedicated preparation-manifest helper", 1L, 0L, "FAIL_CONTRACT", "Helper exited zero but recorded 553 rather than 555 rows",
  "unchanged post-render verifier", 0L, NA_integer_, "NOT_RUN", "The helper postcondition failed first",
  "secure loopback browser QA", 0L, NA_integer_, "NOT_RUN", "Nonvisual acceptance was not reached"
)
write_evidence(invocations, "order57c_invocation_ledger.csv")
add_check(
  "invocations",
  "single render and helper; no post verifier or browser QA",
  paste(invocations$invocation_count, collapse = "/"),
  "1/1/1/0/0",
  "FAIL_CLOSED",
  identical(invocations$invocation_count, c(1L, 1L, 1L, 0L, 0L))
)

summary_paths <- list.files(
  semantic_dir,
  pattern = "summary[.]csv$",
  full.names = TRUE
)
ledger_paths <- list.files(
  semantic_dir,
  pattern = "ledger[.]csv$",
  full.names = TRUE
)
stopifnot(length(summary_paths) == 1L, length(ledger_paths) == 1L)
semantic_summary <- utils::read.csv(summary_paths, check.names = FALSE)
ledger <- utils::read.csv(ledger_paths, check.names = FALSE)
html_path <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html"
)
html_raw <- read_raw_file(html_path)
engine_env <- new.env(parent = globalenv())
sys.source(
  file.path(root, "scripts/report_harmonization/repair_gt_html_semantics.R"),
  envir = engine_env
)
reversed_raw <- engine_env$apply_raw_replacements(
  html_raw,
  ledger,
  reverse = TRUE
)
reapplied_raw <- engine_env$apply_raw_replacements(
  reversed_raw,
  ledger,
  reverse = FALSE
)
html_document <- xml2::read_html(rawToChar(html_raw))
main <- xml2::xml_find_all(
  html_document,
  "//main[@id='quarto-document-content']"
)
tables <- xml2::xml_find_all(
  main,
  paste0(
    ".//table[contains(concat(' ', normalize-space(@class), ' '),",
    " ' gt_table ')]"
  )
)
ids <- xml2::xml_attr(xml2::xml_find_all(html_document, ".//*[@id]"), "id")
ids <- ids[!is.na(ids) & nzchar(ids)]
table_headers_resolve <- vapply(
  tables,
  function(table) {
    table_ids <- xml2::xml_attr(xml2::xml_find_all(table, ".//*[@id]"), "id")
    table_ids <- table_ids[!is.na(table_ids) & nzchar(table_ids)]
    header_values <- xml2::xml_attr(
      xml2::xml_find_all(table, ".//*[@headers]"),
      "headers"
    )
    tokens <- unlist(strsplit(header_values, "[[:space:]]+"), use.names = FALSE)
    length(tokens) > 0L && all(tokens %in% table_ids)
  },
  logical(1)
)
semantic_actual_exact <-
  nrow(semantic_summary) == 1L &&
  semantic_summary$disposition == "REPAIRED" &&
  semantic_summary$table_count == 19L &&
  semantic_summary$id_count == 102L &&
  semantic_summary$headers_count == 591L &&
  semantic_summary$total_substitutions == 693L &&
  nrow(ledger) == 693L &&
  identical(reapplied_raw, html_raw) &&
  length(main) == 1L &&
  length(tables) == 19L &&
  !anyDuplicated(ids) &&
  all(table_headers_resolve)
semantic_contract_exact <-
  semantic_summary$headers_count == 588L &&
  semantic_summary$total_substitutions == 690L
stopifnot(semantic_actual_exact, !semantic_contract_exact)
semantic_audit <- tibble::tibble(
  disposition = semantic_summary$disposition,
  tables = semantic_summary$table_count,
  id_substitutions = semantic_summary$id_count,
  headers_substitutions = semantic_summary$headers_count,
  total_substitutions = semantic_summary$total_substitutions,
  ledger_rows = nrow(ledger),
  exact_reapplication = identical(reapplied_raw, html_raw),
  unique_document_ids = !anyDuplicated(ids),
  all_headers_resolve_within_table = all(table_headers_resolve),
  rendered_html_sha256 = sha256_raw(html_raw),
  rendered_html_bytes = length(html_raw),
  expected_headers_substitutions = 588L,
  expected_total_substitutions = 690L,
  contract_status = "FAIL_CLOSED"
)
write_evidence(semantic_audit, "semantic_postrender_failure_audit.csv")
add_check(
  "semantic contract",
  "actual reversible semantic repair versus sealed count",
  paste(
    semantic_summary$table_count,
    semantic_summary$id_count,
    semantic_summary$headers_count,
    semantic_summary$total_substitutions,
    sep = "/"
  ),
  "19/102/588/690",
  "FAIL_CLOSED",
  semantic_actual_exact && !semantic_contract_exact
)

manifest_rel <- "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv"
manifest_path <- file.path(root, manifest_rel)
manifest <- utils::read.csv(manifest_path, check.names = FALSE)
manifest_files <- file.path(root, manifest$path)
manifest_live_exact <- file.exists(manifest_files) & !dir.exists(manifest_files) &
  vapply(manifest_files, sha256_file, character(1)) == manifest$sha256 &
  file_bytes(manifest_files) == as.numeric(manifest$bytes)
manifest_internal_exact <-
  nrow(manifest) == 553L &&
  !anyDuplicated(manifest$path) &&
  !manifest_rel %in% manifest$path &&
  !any(startsWith(
    manifest$path,
    "audit/hypotheses/H09/report018_order57c_companion_retry/"
  )) &&
  all(manifest_live_exact)
manifest_contract_exact <- nrow(manifest) == 555L
stopifnot(manifest_internal_exact, !manifest_contract_exact)
manifest_audit <- manifest |>
  mutate(live_exact = manifest_live_exact, status = "PASS")
write_evidence(manifest_audit, "preparation_manifest_553_live_audit.csv")
add_check(
  "preparation manifest",
  "helper output rows",
  paste0(nrow(manifest), "/", sum(manifest_live_exact)),
  "555/555",
  "FAIL_CLOSED",
  manifest_internal_exact && !manifest_contract_exact
)

pre_helper <- utils::read.csv(
  file.path(working_dir, "helper_inventory_pre.csv"),
  check.names = FALSE
)
pre_not_post <- sort(setdiff(pre_helper$path, manifest$path))
post_not_pre <- sort(setdiff(manifest$path, pre_helper$path))
source_side_prefix <- "audit/hypotheses/H09/H09_analysis_preparation"
build_asset_prefix <- paste0(
  "_build/nathealth/audit/hypotheses/H09/",
  "H09_analysis_preparation_files/"
)
stopifnot(
  nrow(pre_helper) == 554L,
  length(pre_not_post) == 17L,
  sum(startsWith(pre_not_post, source_side_prefix)) == 17L,
  length(post_not_pre) == 16L,
  all(startsWith(post_not_pre, build_asset_prefix))
)
helper_transition <- bind_rows(
  tibble::tibble(
    path = pre_not_post,
    transition = "PRE_MEMBER_MISSING_AFTER_RENDER",
    status = "FAIL_CLOSED"
  ),
  tibble::tibble(
    path = post_not_pre,
    transition = "NEW_CANONICAL_PAGE_ASSET",
    status = "OBSERVED"
  )
)
write_evidence(helper_transition, "helper_inventory_transition.csv")
add_check(
  "preparation manifest",
  "pre-render to post-helper membership transition",
  paste(length(pre_not_post), length(post_not_pre), sep = "/"),
  "0 missing/1 added figure asset",
  "FAIL_CLOSED",
  length(pre_not_post) == 17L && length(post_not_pre) == 16L
)

support_baseline <- utils::read.csv(
  file.path(
    root,
    "audit/hypotheses/H09/report018_order57a_companion_retry/source_side_support_tree_postfailure.csv"
  ),
  check.names = FALSE
)
support_files <- file.path(root, support_baseline$relative_path)
support_exists <- file.exists(support_files) & !dir.exists(support_files)
local_html_rel <- "audit/hypotheses/H09/H09_analysis_preparation.html"
local_html_exists <- file.exists(file.path(root, local_html_rel))
stopifnot(
  nrow(support_baseline) == 16L,
  sum(support_exists) == 0L,
  !local_html_exists
)
support_audit <- support_baseline |>
  mutate(
    current_exists = support_exists,
    status = "FAIL_CLOSED"
  )
write_evidence(support_audit, "source_side_support_missing_audit.csv")
add_check(
  "source-side preservation",
  "historical HTML and support files",
  paste(as.integer(local_html_exists), sum(support_exists), sep = "/"),
  "1/16 exact",
  "FAIL_CLOSED",
  !local_html_exists && sum(support_exists) == 0L
)

pre_build <- utils::read.csv(
  file.path(working_dir, "build_inventory_prerender.csv"),
  check.names = FALSE
)
build_files <- list.files(
  file.path(root, "_build/nathealth"),
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = FALSE,
  all.files = TRUE,
  no.. = TRUE
)
build_rel <- substring(
  normalizePath(build_files, winslash = "/", mustWork = TRUE),
  nchar(root) + 2L
)
current_build <- tibble::tibble(
  relative_path = build_rel,
  sha256 = vapply(build_files, sha256_file, character(1)),
  bytes = file_bytes(build_files)
)
build_delta <- full_join(
  pre_build |>
    select(.data$relative_path, pre_sha256 = .data$sha256, pre_bytes = .data$bytes),
  current_build |>
    select(.data$relative_path, post_sha256 = .data$sha256, post_bytes = .data$bytes),
  by = "relative_path",
  relationship = "one-to-one"
) |>
  mutate(
    disposition = case_when(
      !is.na(.data$pre_sha256) & !is.na(.data$post_sha256) &
        .data$pre_sha256 == .data$post_sha256 &
        as.numeric(.data$pre_bytes) == .data$post_bytes ~ "UNCHANGED",
      is.na(.data$pre_sha256) & !is.na(.data$post_sha256) ~ "ADDED",
      !is.na(.data$pre_sha256) & is.na(.data$post_sha256) ~ "MISSING",
      TRUE ~ "CHANGED"
    )
  )
added_paths <- sort(build_delta$relative_path[build_delta$disposition == "ADDED"])
changed_paths <- sort(build_delta$relative_path[build_delta$disposition == "CHANGED"])
missing_build_paths <- build_delta$relative_path[build_delta$disposition == "MISSING"]
expected_changed <- sort(c(
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "_build/nathealth/search.json",
  "_build/nathealth/sitemap.xml"
))
stopifnot(
  nrow(pre_build) == 851L,
  nrow(current_build) == 871L,
  length(added_paths) == 20L,
  length(changed_paths) == 4L,
  identical(changed_paths, expected_changed),
  length(missing_build_paths) == 0L,
  sum(startsWith(added_paths, build_asset_prefix)) == 16L,
  sum(startsWith(added_paths, "_build/nathealth/artifacts/")) == 4L
)
write_evidence(build_delta, "build_delta_postrender.csv")
add_check(
  "build",
  "post-render build membership",
  paste(nrow(pre_build), nrow(current_build), length(added_paths), length(changed_paths), sep = "/"),
  "851/852/1 target asset/target-owned changes",
  "FAIL_CLOSED",
  nrow(current_build) == 871L && length(added_paths) == 20L
)

protected_baseline <- utils::read.csv(
  file.path(
    root,
    "audit/hypotheses/H09/report018_order57a_companion_retry/protected_inventory_postfailure.csv"
  ),
  check.names = FALSE
)
protected_files <- file.path(root, protected_baseline$relative_path)
protected_exists <- file.exists(protected_files) & !dir.exists(protected_files)
protected_sha <- rep(NA_character_, nrow(protected_baseline))
protected_bytes <- rep(NA_real_, nrow(protected_baseline))
protected_sha[protected_exists] <- vapply(
  protected_files[protected_exists],
  sha256_file,
  character(1)
)
protected_bytes[protected_exists] <- file_bytes(protected_files[protected_exists])
protected_exact <- protected_exists &
  protected_sha == protected_baseline$sha256 &
  protected_bytes == as.numeric(protected_baseline$bytes)
protected_audit <- protected_baseline |>
  mutate(
    current_exists = protected_exists,
    observed_sha256 = protected_sha,
    observed_bytes = protected_bytes,
    disposition = case_when(
      protected_exact ~ "HISTORICAL_EXACT",
      !protected_exists ~ "MISSING",
      TRUE ~ "CHANGED"
    )
  )
stopifnot(
  nrow(protected_audit) == 545L,
  sum(protected_audit$disposition == "HISTORICAL_EXACT") == 524L,
  sum(protected_audit$disposition == "MISSING") == 17L,
  sum(protected_audit$disposition == "CHANGED") == 4L
)
write_evidence(protected_audit, "protected_postrender_audit.csv")
add_check(
  "protected inventory",
  "historical exact, missing, and changed rows",
  paste(
    sum(protected_audit$disposition == "HISTORICAL_EXACT"),
    sum(protected_audit$disposition == "MISSING"),
    sum(protected_audit$disposition == "CHANGED"),
    sep = "/"
  ),
  "545/0/authorized target transitions only",
  "FAIL_CLOSED",
  sum(protected_audit$disposition == "MISSING") == 17L
)

generated_figure <- file.path(
  root,
  build_asset_prefix,
  "figure-html/fig-h09-prep-sample-support-1.png"
)
historical_figure <- support_baseline |>
  filter(grepl("fig-h09-prep-sample-support-1[.]png$", .data$relative_path))
stopifnot(
  nrow(historical_figure) == 1L,
  sha256_file(generated_figure) == historical_figure$sha256,
  file_bytes(generated_figure) == as.numeric(historical_figure$bytes)
)
figure_identity <- tibble::tibble(
  current_path = relative_path <- substring(
    normalizePath(generated_figure, winslash = "/", mustWork = TRUE),
    nchar(root) + 2L
  ),
  current_sha256 = sha256_file(generated_figure),
  current_bytes = file_bytes(generated_figure),
  historical_sha256 = historical_figure$sha256,
  historical_bytes = as.numeric(historical_figure$bytes),
  exact = TRUE,
  status = "PASS"
)
write_evidence(figure_identity, "sample_support_figure_identity.csv")
add_check(
  "figure",
  "target-generated sample-support PNG scientific identity",
  paste(figure_identity$current_sha256, figure_identity$current_bytes, sep = "/"),
  paste(historical_figure$sha256, historical_figure$bytes, sep = "/"),
  "PASS",
  TRUE
)

stopifnot(
  all(checks$evidence_status == "PASS"),
  sum(checks$contract_status == "FAIL_CLOSED") == 7L
)
write_evidence(checks, "order57c_failure_verification.csv")
cat(sprintf(
  paste0(
    "REPORT018_H09_ORDER57C_FAIL_CLOSED=PASS pre=12/12 process=0 ",
    "render=1 helper=1 manifest=553/555 semantic=19/102/591/693 ",
    "expected_semantic=19/102/588/690 source_side_missing=17 ",
    "build=851->871 protected=524/17/4 pins=15/15 R=%s\n"
  ),
  as.character(getRversion())
))
