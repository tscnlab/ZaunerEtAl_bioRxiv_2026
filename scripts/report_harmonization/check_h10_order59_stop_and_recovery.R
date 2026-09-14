#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_root <- file.path(
  root,
  "audit/report_harmonization/report018_h10_order59_recovery_preflight"
)
owner_root <- file.path(
  root,
  paste0(
    "audit/hypotheses/H10/",
    "report018_order59_companion_no_rerender_completion"
  )
)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

file_bytes <- function(path) unname(as.numeric(file.info(path)$size))

file_exact <- function(path, sha256, bytes = NULL) {
  pass <- file.exists(path) &&
    !dir.exists(path) &&
    identical(sha256_file(path), sha256)
  if (!is.null(bytes)) {
    pass <- pass && identical(file_bytes(path), as.numeric(bytes))
  }
  pass
}

owner_manifest_path <- file.path(
  owner_root,
  "order59_fail_closed_non_circular_evidence_manifest.csv"
)
owner_manifest <- read.csv(owner_manifest_path, check.names = FALSE)
owner_paths <- file.path(root, owner_manifest$path)
owner_exact <- vapply(
  seq_len(nrow(owner_manifest)),
  function(index) {
    file_exact(
      owner_paths[[index]],
      owner_manifest$sha256[[index]],
      owner_manifest$bytes[[index]]
    )
  },
  logical(1)
)

stopifnot(
  nrow(owner_manifest) == 31L,
  !anyDuplicated(owner_manifest$path),
  !basename(owner_manifest_path) %in% basename(owner_manifest$path),
  all(owner_exact),
  file_exact(
    owner_manifest_path,
    "841fd913ca48bee3c56461b9815dcf89664f72563c3d8bacfff81d151d594ea5",
    5734
  )
)

preview_path <- file.path(
  root,
  paste0(
    "audit/report_harmonization/report018_h10_companion_preflight/",
    "prospective_preparation_report_manifest_preview.csv"
  )
)
current_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv"
)
preview <- read.csv(preview_path, check.names = FALSE)
current <- read.csv(current_manifest_path, check.names = FALSE)

exact_six <- paste0(
  "audit/hypotheses/H10/",
  "report018_order59_companion_no_rerender_completion/",
  c(
    "helper_transition.diff",
    "independent_build_delta.csv",
    "independent_preflight_checks.csv",
    "independent_protected_delta.csv",
    "preparation_test_transition.diff",
    "transition_checks.csv"
  )
)
extra <- sort(setdiff(current$path, preview$path))
missing <- sort(setdiff(preview$path, current$path))
common <- merge(
  current[, c("path", "sha256", "bytes")],
  preview[, c("path", "sha256", "bytes")],
  by = "path",
  suffixes = c("_current", "_preview")
)
common_changed <- common[
  common$sha256_current != common$sha256_preview |
    common$bytes_current != common$bytes_preview,
  ,
  drop = FALSE
]
current_member_exact <- vapply(
  seq_len(nrow(current)),
  function(index) {
    file_exact(
      file.path(root, current$path[[index]]),
      current$sha256[[index]],
      current$bytes[[index]]
    )
  },
  logical(1)
)

stopifnot(
  nrow(current) == 275L,
  !anyDuplicated(current$path),
  all(current_member_exact),
  identical(extra, sort(exact_six)),
  length(missing) == 0L,
  nrow(common_changed) == 0L,
  file_exact(
    current_manifest_path,
    "056d875d4459c52fef87d2c1895da8d157558c3097187fe77aac8aa21005b19c",
    205083
  )
)

six_rows <- current[
  match(sort(exact_six), current$path),
  c("path", "role", "sha256", "bytes"),
  drop = FALSE
]
six_rows$classification <- "created_before_consumed_helper_execution"
write.csv(
  six_rows,
  file.path(evidence_root, "order59_exact_six_row_diagnosis.csv"),
  row.names = FALSE,
  na = ""
)

historical_names <- c(
  "execution_record.csv",
  "fail_closed_checks.csv",
  "fixed_identity_at_stop.csv",
  "helper_mismatch_diagnosis.csv",
  "helper_transition.diff",
  "independent_build_delta.csv",
  "independent_preflight_checks.csv",
  "independent_protected_delta.csv",
  "order59_fail_closed_non_circular_evidence_manifest.csv",
  "order59_fail_closed_stop_record.md",
  "preparation_test_transition.diff",
  "seal_order59_fail_closed.R",
  "transition_checks.csv"
)
observed_historical_names <- sort(list.files(
  owner_root,
  recursive = FALSE,
  include.dirs = FALSE
))
stopifnot(identical(observed_historical_names, sort(historical_names)))

historical_paths <- file.path(owner_root, sort(historical_names))
historical_relative <- substring(historical_paths, nchar(root) + 2L)
historical_inventory <- data.frame(
  path = historical_relative,
  sha256 = vapply(historical_paths, sha256_file, character(1)),
  bytes = file_bytes(historical_paths),
  phase = ifelse(
    historical_relative %in% exact_six,
    "created_before_consumed_helper_execution",
    "created_after_consumed_helper_execution"
  ),
  exclusion_basis = paste(
    "Historical Order 59 execution evidence is sealed separately and",
    "must not enter the chronological live preparation inventory."
  ),
  stringsAsFactors = FALSE
)
write.csv(
  historical_inventory,
  file.path(evidence_root, "order59_historical_evidence_exclusions.csv"),
  row.names = FALSE,
  na = ""
)

prospective_helper_path <- file.path(
  evidence_root,
  "prospective_build_h10_preparation_report_manifest.R"
)
stopifnot(file_exact(
  prospective_helper_path,
  "26619260657ec0cb1d7ac7614af9e3e349a524ee242dd5645b27e31f4cb142f0",
  11294
))

prospective_lines <- readLines(
  prospective_helper_path,
  warn = FALSE,
  encoding = "UTF-8"
)
block_start <- match(
  "historical_order59_evidence <- file.path(",
  prospective_lines
)
block_end <- match(
  "audit_files <- setdiff(audit_files, historical_order59_evidence)",
  prospective_lines
)
stopifnot(
  !is.na(block_start),
  !is.na(block_end),
  block_start < block_end
)
reversed_lines <- prospective_lines[-seq.int(block_start, block_end)]
reversed_path <- tempfile(fileext = ".R")
writeLines(reversed_lines, reversed_path, useBytes = TRUE)
stopifnot(file_exact(
  reversed_path,
  "292ad3335dac8241f317983d5017a5a1d5dbce51fef245d2c30889cf4a3dcf97",
  10437
))

replay_manifest_path <- file.path(
  evidence_root,
  "isolated_recovery_manifest.csv"
)
replay <- read.csv(replay_manifest_path, check.names = FALSE)
replay_lookup <- file.path(root, replay$path)
helper_row <- replay$path ==
  "scripts/hypotheses/H10/build_h10_preparation_report_manifest.R"
replay_lookup[helper_row] <- prospective_helper_path
replay_member_exact <- vapply(
  seq_len(nrow(replay)),
  function(index) {
    file_exact(
      replay_lookup[[index]],
      replay$sha256[[index]],
      replay$bytes[[index]]
    )
  },
  logical(1)
)

replay_common <- merge(
  replay[, c("path", "sha256", "bytes")],
  preview[, c("path", "sha256", "bytes")],
  by = "path",
  suffixes = c("_replay", "_preview")
)
replay_changed <- replay_common[
  replay_common$sha256_replay != replay_common$sha256_preview |
    replay_common$bytes_replay != replay_common$bytes_preview,
  ,
  drop = FALSE
]
stopifnot(
  file_exact(
    replay_manifest_path,
    "08642e6e290e253340c414df1e0497619b4717374032bcc168667a955a5772e6",
    200487
  ),
  nrow(replay) == 269L,
  !anyDuplicated(replay$path),
  setequal(replay$path, preview$path),
  all(replay_member_exact),
  nrow(replay_changed) == 1L,
  identical(
    replay_changed$path,
    "scripts/hypotheses/H10/build_h10_preparation_report_manifest.R"
  ),
  !any(startsWith(
    replay$path,
    paste0(
      "audit/hypotheses/H10/",
      "report018_order59_companion_no_rerender_completion/"
    )
  ))
)

fixed <- data.frame(
  path = c(
    "notebooks/hypotheses/H10.qmd",
    "_build/nathealth/notebooks/hypotheses/H10.html",
    "audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.html",
    "tests/hypotheses/H10/test_h10_preparation_report.R",
    "tests/hypotheses/H10/test_h10_stage3_reader_report.R",
    "_quarto-nathealth.yml",
    "notebooks/hypotheses/H11.qmd"
  ),
  sha256 = c(
    "0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d",
    "37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14",
    "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6",
    "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6",
    "dc2aa864a1b1edf01043444af425df40564779e83b72f00c206068fdba19a7b9",
    "8b206d4cf565b6f5a767e6e99afb9e587db8255f2239cb3761eebaa8e69d1608",
    "dac8e70f9389bac48bfb91fd0640f86b3a65e468d52aa2dbb37a63d9aa0303af",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867"
  )
)
fixed$exact <- vapply(
  seq_len(nrow(fixed)),
  function(index) file_exact(fixed$path[[index]], fixed$sha256[[index]]),
  logical(1)
)
stopifnot(all(fixed$exact))

html_path <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.html"
)
document <- xml2::read_html(html_path)
main <- xml2::xml_find_all(
  document,
  "//main[@id='quarto-document-content']"
)
tables <- xml2::xml_find_all(
  main,
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
images <- xml2::xml_attr(xml2::xml_find_all(main, ".//img"), "src")
expected_images <- c(
  "../../../artifacts/10_figures/H10/H10_preparation_age_distribution.png",
  "../../../artifacts/10_figures/H10/H10_preparation_sample_support.png"
)
all_ids <- xml2::xml_attr(xml2::xml_find_all(document, "//*[@id]"), "id")
header_values <- xml2::xml_attr(
  xml2::xml_find_all(tables, ".//*[@headers]"),
  "headers"
)
header_tokens <- unlist(strsplit(header_values, "\\s+", perl = TRUE))
header_tokens <- header_tokens[nzchar(header_tokens)]

stopifnot(
  length(main) == 1L,
  length(tables) == 19L,
  identical(images[images %in% expected_images], expected_images),
  anyDuplicated(all_ids) == 0L,
  length(header_tokens) == 1050L,
  all(vapply(
    header_tokens,
    function(token) sum(all_ids == token) == 1L,
    logical(1)
  )),
  length(xml2::xml_find_all(
    main,
    ".//*[contains(concat(' ', normalize-space(@class), ' '), ' cell-output-error ')]"
  )) ==
    0L
)

execution <- read.csv(
  file.path(evidence_root, "isolated_recovery_execution.csv"),
  check.names = FALSE
)
visual <- read.csv(
  file.path(evidence_root, "isolated_visual_qa_observations.csv"),
  check.names = FALSE
)
stopifnot(
  nrow(execution) == 4L,
  all(execution$status == "PASS"),
  nrow(visual) == 10L,
  all(visual$status == "PASS")
)

checks <- data.frame(
  domain = c(
    "owner_stop",
    "manifest_diagnosis",
    "historical_evidence",
    "helper_transition",
    "isolated_manifest",
    "isolated_test",
    "semantic_dom",
    "fixed_identity",
    "visual_preflight",
    "execution_scope"
  ),
  check_id = c(
    "owner_seal_exact",
    "exact_six_extra_rows",
    "exact_thirteen_file_exclusion_set",
    "prospective_helper_and_exact_reverse",
    "recovery_manifest_269_live_exact",
    "strict_preparation_test_pass",
    "existing_html_semantic_contract",
    "sources_html_profile_and_h11_exact",
    "secure_loopback_responsive_preflight",
    "no_quarto_science_or_html_mutation"
  ),
  status = rep("PASS", 10L),
  detail = c(
    "31/31 exact, unique, non-circular",
    "275 versus 269; extra=6, missing=0, common_changed=0",
    "13/13 exact historical Order 59 files excluded",
    paste0(
      "post=26619260; reverse=292ad333; R=4.6.1; Air=0.4.1"
    ),
    "269/269 live-exact; preview path set exact; helper row only changed",
    "19 gt tables, 2 descriptive figures, 68 frozen frames; strict mode",
    "main=1 tables=19 figures=2 headers=1050 duplicate_ids=0 errors=0",
    "9/9 exact",
    "1440x1000, 708x1000, 720x500, 642px figures; clean load and teardown",
    "Quarto=0; QMD execution=0; model/science=0; canonical HTML change=0"
  ),
  stringsAsFactors = FALSE
)

output_path <- file.path(
  evidence_root,
  "report018_h10_order59_recovery_preflight_checks.csv"
)
write.csv(checks, output_path, row.names = FALSE, na = "")
cat(
  paste0(
    "REPORT018_H10_ORDER59_RECOVERY_PREFLIGHT=PASS ",
    "owner=31/31 six=6/6 historical=13/13 manifest=269/269 ",
    "test=PASS tables=19 figures=2 headers=1050 visual=10/10 R=4.6.1\n"
  )
)
