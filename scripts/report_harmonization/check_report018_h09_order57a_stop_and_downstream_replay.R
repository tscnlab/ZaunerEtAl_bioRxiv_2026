#!/usr/bin/env Rscript

# Independently reproduce the H09 order-57a stopped state, classify the exact
# 19 historical Stage 3 manifest identities, and exercise the complete
# remaining companion source, helper, semantic, and preservation path before
# a single continuation may be released.

Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE, warn = 2, lifecycle_verbosity = "quiet")

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H09 order-57a downstream audit requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(knitr)
  library(tibble)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

source(file.path(
  root,
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
))

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

sha256_raw <- function(value) {
  digest::digest(value, algo = "sha256", serialize = FALSE)
}

file_bytes <- function(path) {
  unname(file.info(path)$size)
}

read_raw_file <- function(path) {
  readBin(path, what = "raw", n = file_bytes(path))
}

write_audit <- function(value, name) {
  path <- file.path(root, "audit/report_harmonization", name)
  utils::write.csv(value, path, row.names = FALSE, na = "")
  invisible(path)
}

checks <- tibble::tibble(
  domain = character(),
  check = character(),
  observed = character(),
  expected = character(),
  status = character()
)

add_check <- function(domain, check, observed, expected, pass) {
  checks <<- bind_rows(
    checks,
    tibble::tibble(
      domain = domain,
      check = check,
      observed = paste(observed, collapse = "|"),
      expected = paste(expected, collapse = "|"),
      status = if (isTRUE(pass)) "PASS" else "FAIL"
    )
  )
}

audit_manifest <- function(path, expected_rows) {
  manifest <- utils::read.csv(path, check.names = FALSE)
  manifest_rel <- substring(path, nchar(root) + 2L)
  files <- ifelse(
    startsWith(manifest$path, "/"),
    manifest$path,
    file.path(root, manifest$path)
  )
  exists <- file.exists(files) & !dir.exists(files)
  observed_sha <- rep(NA_character_, nrow(manifest))
  observed_bytes <- rep(NA_real_, nrow(manifest))
  observed_sha[exists] <- vapply(
    files[exists],
    sha256_file,
    character(1)
  )
  observed_bytes[exists] <- file_bytes(files[exists])
  audit <- manifest |>
    mutate(
      observed_sha256 = observed_sha,
      observed_bytes = observed_bytes,
      status = if_else(
        exists &
          .data$sha256 == .data$observed_sha256 &
          as.numeric(.data$bytes) == .data$observed_bytes,
        "PASS",
        "FAIL"
      )
    )
  stopifnot(
    nrow(manifest) == expected_rows,
    !anyDuplicated(manifest$path),
    !manifest_rel %in% manifest$path,
    all(audit$status == "PASS")
  )
  audit
}

stop_dir_rel <- "audit/hypotheses/H09/report018_order57a_companion_retry"
stop_dir <- file.path(root, stop_dir_rel)
stop_record_rel <- file.path(stop_dir_rel, "ORDER57A_FAIL_CLOSED.md")
stop_verifier_rel <- file.path(
  stop_dir_rel,
  "verify_order57a_h09_companion_failure.R"
)
stop_verification_rel <- file.path(
  stop_dir_rel,
  "order57a_failure_verification.csv"
)
stop_manifest_rel <- file.path(
  stop_dir_rel,
  "order57a_fail_closed_evidence_manifest.csv"
)
mismatch_rel <- file.path(stop_dir_rel, "reader_manifest_mismatches_sealed.csv")
live_audit_rel <- file.path(
  stop_dir_rel,
  "reader_manifest_live_audit_sealed.csv"
)

expected_stop <- tibble::tribble(
  ~path,
  ~sha256,
  ~bytes,
  stop_record_rel,
  "d484752e15aee7eaf55750360e09df3958c4679c4f76dc78f20c84745afc6ada",
  5661,
  stop_verifier_rel,
  "2d357cc0fbf3305071c1e825911a7583165354adb3682063a2eabde66e8bc5e6",
  17133,
  stop_verification_rel,
  "1d212cbc0daa7887a73b2706b99198db49f417ef31f8d3296621294baa13947c",
  1997,
  stop_manifest_rel,
  "89126ec7990c41ecbe8956c05b33926e29fdc0f42011b1383447beaccf2626f8",
  11573,
  mismatch_rel,
  "7442ab696510b055a71018795cb5fa5366d0d67933b587fe17dafe81b09d191d",
  6215,
  live_audit_rel,
  "ce02b3076d920c8417c163238143cb5d6421dd9114d4af49bf9fa72c4384c36b",
  34794
)
stop_files <- file.path(root, expected_stop$path)
stop_pin_pass <- vapply(stop_files, sha256_file, character(1)) ==
  expected_stop$sha256 &
  file_bytes(stop_files) == expected_stop$bytes
stopifnot(all(stop_pin_pass))
add_check(
  "stopped state",
  "direct stop identities",
  sum(stop_pin_pass),
  nrow(expected_stop),
  all(stop_pin_pass)
)

owner_manifest_audit <- audit_manifest(
  file.path(root, stop_manifest_rel),
  58L
)
add_check(
  "stopped state",
  "owner non-circular seal",
  paste0(sum(owner_manifest_audit$status == "PASS"), "/58"),
  "58/58",
  all(owner_manifest_audit$status == "PASS")
)

owner_verification <- utils::read.csv(
  file.path(root, stop_verification_rel),
  check.names = FALSE
)
stopifnot(
  nrow(owner_verification) == 17L,
  all(owner_verification$status == "PASS")
)
add_check(
  "stopped state",
  "owner failure verification",
  paste0(sum(owner_verification$status == "PASS"), "/17"),
  "17/17",
  all(owner_verification$status == "PASS")
)

stage3_rel <- "artifacts/12_manifests/H09/H09_stage3_artifacts.csv"
stage3_path <- file.path(root, stage3_rel)
stopifnot(
  sha256_file(stage3_path) ==
    "0103aad8bf3b2424358fc139b85b95564054745b180a80d1e12c27ff72e1bef2",
  file_bytes(stage3_path) == 24678
)
reader_manifest <- utils::read.csv(stage3_path, check.names = FALSE)
mutable_records <- c(
  "audit/handoffs/H09_worker_handoff.md",
  "audit/handoffs/H09_shared_change_request.md"
)
immutable_reader_manifest <- reader_manifest |>
  filter(!.data$path %in% mutable_records)
manifest_files <- file.path(root, immutable_reader_manifest$path)
manifest_exists <- file.exists(manifest_files) & !dir.exists(manifest_files)
manifest_current_sha <- rep(NA_character_, nrow(immutable_reader_manifest))
manifest_current_bytes <- rep(NA_real_, nrow(immutable_reader_manifest))
manifest_current_sha[manifest_exists] <- unname(vapply(
  manifest_files[manifest_exists],
  sha256_file,
  character(1)
))
manifest_current_bytes[manifest_exists] <- unname(
  file_bytes(manifest_files[manifest_exists])
)
manifest_audit <- immutable_reader_manifest |>
  mutate(
    current_sha256 = manifest_current_sha,
    current_bytes = manifest_current_bytes,
    path_exists = manifest_exists,
    live_exact = .data$path_exists &
      .data$sha256 == .data$current_sha256 &
      as.numeric(.data$bytes) == .data$current_bytes,
    status = if_else(.data$live_exact, "PASS", "FAIL")
  )

sealed_live <- utils::read.csv(
  file.path(root, live_audit_rel),
  check.names = FALSE
)
sealed_mismatches <- utils::read.csv(
  file.path(root, mismatch_rel),
  check.names = FALSE
)
stopifnot(
  nrow(reader_manifest) == 108L,
  !anyDuplicated(reader_manifest$path),
  nrow(immutable_reader_manifest) == 106L,
  all(manifest_exists),
  nrow(sealed_live) == 106L,
  nrow(sealed_mismatches) == 19L,
  !anyDuplicated(sealed_mismatches$path),
  sum(manifest_audit$live_exact) == 87L,
  identical(
    sort(manifest_audit$path[!manifest_audit$live_exact]),
    sort(sealed_mismatches$path)
  )
)
sealed_current <- sealed_mismatches |>
  transmute(
    path = .data$path,
    historical_sha256 = .data$sha256,
    historical_bytes = as.numeric(.data$bytes),
    current_sha256 = .data$current_sha256,
    current_bytes = as.numeric(.data$current_bytes)
  ) |>
  arrange(.data$path)
observed_current <- manifest_audit |>
  filter(!.data$live_exact) |>
  transmute(
    path = .data$path,
    historical_sha256 = .data$sha256,
    historical_bytes = as.numeric(.data$bytes),
    current_sha256 = .data$current_sha256,
    current_bytes = as.numeric(.data$current_bytes)
  ) |>
  arrange(.data$path)
stopifnot(identical(observed_current, sealed_current))
add_check(
  "Stage 3 manifest",
  "live and historical rows",
  paste0(sum(manifest_audit$live_exact), "+", nrow(sealed_mismatches)),
  "87+19",
  sum(manifest_audit$live_exact) == 87L && nrow(sealed_mismatches) == 19L
)

preparation_manifest_rel <-
  "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv"
display_manifest_rel <- paste0(
  "audit/hypotheses/H09/report018_order56b_environment_retry/",
  "current_display_manifest.csv"
)
postimages_rel <- file.path(
  stop_dir_rel,
  "authorized_postimages_postfailure.csv"
)
scope_audit_rel <-
  "audit/report_harmonization/report018_h09_order57_scientific_scope_audit.csv"
release_pins_rel <-
  "audit/report_harmonization/report018_h09_result_release_pins.csv"
metric011_reseal_manifest_rel <-
  "artifacts/12_manifests/H09/H09_METRIC-011_provenance_reseal_manifest.csv"

authority_pins <- tibble::tribble(
  ~path,
  ~sha256,
  ~bytes,
  preparation_manifest_rel,
  "8e1d633262b33df64e45f0fc3fd677f4bb1e8a69120cb76a9b152509b94f0aaf",
  35323,
  display_manifest_rel,
  "53a3981a7de6684444025e2d763efc4ef2884ca4ec385e93a87a89d18ee73e27",
  3416,
  postimages_rel,
  "ec1ba2a135d3b7bb875298bd6d14d8f083fa1f56c51a8452030b59ef08546ebc",
  685,
  scope_audit_rel,
  "7c1f13045eaa7d7067f3feb8ef995c85387500eb83c9a390205ab4823e1a00a9",
  2122,
  release_pins_rel,
  "d65f20daa2ec1955aaa48bcdf7a9ec6c4e98c84c444a5d24348fe807a1578947",
  6015,
  metric011_reseal_manifest_rel,
  "cb4e0701c0f642c36e138ef670af373eeeef850e538a991af32bcf7f63583cad",
  6164
)
authority_files <- file.path(root, authority_pins$path)
authority_exact <- vapply(authority_files, sha256_file, character(1)) ==
  authority_pins$sha256 &
  file_bytes(authority_files) == authority_pins$bytes
stopifnot(all(authority_exact))

preparation_manifest <- utils::read.csv(
  file.path(root, preparation_manifest_rel),
  check.names = FALSE
)
display_manifest <- utils::read.csv(
  file.path(root, display_manifest_rel),
  check.names = FALSE
)
postimages <- utils::read.csv(
  file.path(root, postimages_rel),
  check.names = FALSE
)
release_pins <- utils::read.csv(
  file.path(root, release_pins_rel),
  check.names = FALSE
)
metric011_reseal_manifest <- utils::read.csv(
  file.path(root, metric011_reseal_manifest_rel),
  check.names = FALSE
)
scope_audit <- utils::read.csv(
  file.path(root, scope_audit_rel),
  check.names = FALSE
)
stopifnot(nrow(scope_audit) == 20L, all(scope_audit$status == "PASS"))

preparation_authority_paths <-
  "audit/hypotheses/H09/H09_stage1_gate_and_stage2_transition.md"
metric011_authority_path <- "artifacts/06_model_data/H09/H09_base_bundle_audit.csv"
postimage_authority_paths <- c(
  "scripts/hypotheses/H09/h09_contract.R",
  "artifacts/06_model_data/H09/H09_input_audit.csv"
)
display_authority_paths <- c(
  "scripts/hypotheses/H09/run_h09_stage2.R",
  "artifacts/10_figures/H09/H09_diagnostics_chest.pdf",
  "artifacts/10_figures/H09/H09_diagnostics_chest.png",
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.pdf",
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.png",
  "artifacts/10_figures/H09/H09_paired_placement_effects.pdf",
  "artifacts/10_figures/H09/H09_paired_placement_effects.png",
  "artifacts/10_figures/H09/H09_primary_effects.pdf",
  "artifacts/10_figures/H09/H09_primary_effects.png",
  "artifacts/12_manifests/H09/H09_figure_manifest.csv",
  "_build/nathealth/notebooks/hypotheses/H09.html",
  "notebooks/hypotheses/H09.qmd"
)
release_authority_paths <- c(
  "_quarto-nathealth.yml",
  "audit/decisions/figure_readability_and_layout.md"
)
registry_authority_path <- "config/metric_display_registry.csv"
stopifnot(
  length(c(
    preparation_authority_paths,
    metric011_authority_path,
    postimage_authority_paths,
    display_authority_paths,
    release_authority_paths,
    registry_authority_path
  )) ==
    19L
)

classification <- sealed_mismatches |>
  transmute(
    path = .data$path,
    historical_sha256 = .data$sha256,
    historical_bytes = as.numeric(.data$bytes),
    live_sha256 = .data$current_sha256,
    live_bytes = as.numeric(.data$current_bytes),
    authority = case_when(
      .data$path %in% preparation_authority_paths ~
        "current row in immutable H09 preparation manifest",
      .data$path == metric011_authority_path ~
        "accepted METRIC-011 H09 provenance reseal",
      .data$path %in% postimage_authority_paths ~
        "order57a exact authorized postimage and reverse proof",
      .data$path %in% display_authority_paths ~
        "order56b accepted current display or result identity",
      .data$path %in% release_authority_paths ~
        "accepted REPORT-018 H09 result release pin",
      .data$path == registry_authority_path ~
        "order57 MDER-only scientific-scope adjudication",
      TRUE ~ "UNCLASSIFIED"
    ),
    authority_path = case_when(
      .data$path %in% preparation_authority_paths ~ preparation_manifest_rel,
      .data$path == metric011_authority_path ~ metric011_reseal_manifest_rel,
      .data$path %in% postimage_authority_paths ~ postimages_rel,
      .data$path %in% display_authority_paths ~ display_manifest_rel,
      .data$path %in% release_authority_paths ~ release_pins_rel,
      .data$path == registry_authority_path ~ scope_audit_rel,
      TRUE ~ ""
    )
  )

authority_row_exact <- vapply(
  seq_len(nrow(classification)),
  function(index) {
    row <- classification[index, , drop = FALSE]
    if (row$path %in% preparation_authority_paths) {
      authority_row <- preparation_manifest[
        preparation_manifest$path == row$path,
      ]
      return(
        nrow(authority_row) == 1L &&
          authority_row$sha256 == row$live_sha256 &&
          as.numeric(authority_row$bytes) == row$live_bytes
      )
    }
    if (row$path == metric011_authority_path) {
      authority_row <- metric011_reseal_manifest[
        metric011_reseal_manifest$path == row$path,
      ]
      return(
        nrow(authority_row) == 1L &&
          authority_row$sha256 == row$live_sha256 &&
          as.numeric(authority_row$bytes) == row$live_bytes &&
          authority_row$status == "PASS"
      )
    }
    if (row$path %in% postimage_authority_paths) {
      authority_row <- postimages[postimages$path == row$path, ]
      return(
        nrow(authority_row) == 1L &&
          authority_row$expected_sha256 == row$live_sha256 &&
          as.numeric(authority_row$expected_bytes) == row$live_bytes &&
          authority_row$status == "PASS"
      )
    }
    if (row$path %in% display_authority_paths) {
      authority_row <- display_manifest[
        display_manifest$relative_path == row$path,
      ]
      return(
        nrow(authority_row) == 1L &&
          authority_row$sha256 == row$live_sha256 &&
          as.numeric(authority_row$bytes) == row$live_bytes
      )
    }
    if (row$path %in% release_authority_paths) {
      authority_row <- release_pins[release_pins$relative_path == row$path, ]
      return(
        nrow(authority_row) == 1L &&
          authority_row$sha256 == row$live_sha256 &&
          as.numeric(authority_row$bytes) == row$live_bytes
      )
    }
    if (row$path == registry_authority_path) {
      authority_row <- release_pins[release_pins$relative_path == row$path, ]
      scope_ok <- scope_audit |>
        filter(
          .data$domain == "registry",
          .data$check %in%
            c(
              "current registry identity",
              "only changed registry construct",
              "H09 shared display rows"
            )
        )
      return(
        nrow(authority_row) == 1L &&
          authority_row$sha256 == row$live_sha256 &&
          as.numeric(authority_row$bytes) == row$live_bytes &&
          nrow(scope_ok) == 3L &&
          all(scope_ok$status == "PASS")
      )
    }
    FALSE
  },
  logical(1)
)
classification$authority_row_exact <- authority_row_exact
classification$disposition <- ifelse(
  authority_row_exact,
  "ACCEPTED_HISTORICAL_TO_LIVE",
  "FAIL"
)
stopifnot(
  nrow(classification) == 19L,
  !anyDuplicated(classification$path),
  !any(classification$authority == "UNCLASSIFIED"),
  all(classification$authority_row_exact),
  all(classification$disposition == "ACCEPTED_HISTORICAL_TO_LIVE")
)
add_check(
  "classification",
  "closed 19-row authority set",
  paste0(sum(classification$authority_row_exact), "/19"),
  "19/19",
  all(classification$authority_row_exact)
)

transition_sha <-
  "7442ab696510b055a71018795cb5fa5366d0d67933b587fe17dafe81b09d191d"
transition_bytes <- 6215
replacement <- c(
  "mutable_records <- c(",
  "  \"audit/handoffs/H09_worker_handoff.md\",",
  "  \"audit/handoffs/H09_shared_change_request.md\"",
  ")",
  "accepted_transition_path <- file.path(",
  "  root,",
  "  \"audit/hypotheses/H09/report018_order57a_companion_retry\",",
  "  \"reader_manifest_mismatches_sealed.csv\"",
  ")",
  "stopifnot(",
  paste0(
    "  artifact_sha256(accepted_transition_path) == \"",
    transition_sha,
    "\","
  ),
  paste0(
    "  unname(file.info(accepted_transition_path)$size) == ",
    transition_bytes
  ),
  ")",
  "accepted_reader_transitions <- readr::read_csv(",
  "  accepted_transition_path,",
  "  show_col_types = FALSE,",
  "  progress = FALSE",
  ")",
  "required_transition_columns <- c(",
  "  \"path\", \"sha256\", \"bytes\", \"current_sha256\",",
  "  \"current_bytes\", \"path_exists\", \"status\"",
  ")",
  "stopifnot(",
  "  nrow(accepted_reader_transitions) == 19L,",
  "  !anyDuplicated(accepted_reader_transitions$path),",
  "  all(required_transition_columns %in% names(accepted_reader_transitions)),",
  "  all(accepted_reader_transitions$path_exists),",
  "  all(accepted_reader_transitions$status == \"FAIL\"),",
  "  all(nchar(accepted_reader_transitions$sha256) == 64L),",
  "  all(nchar(accepted_reader_transitions$current_sha256) == 64L)",
  ")",
  "expected_historical_paths <- accepted_reader_transitions$path",
  "immutable_reader_manifest <- reader_manifest |>",
  "  filter(!.data$path %in% mutable_records)",
  "manifest_paths <- file.path(root, immutable_reader_manifest$path)",
  "manifest_exists <- file.exists(manifest_paths)",
  "manifest_current_sha <- rep(NA_character_, length(manifest_paths))",
  "manifest_current_bytes <- rep(NA_real_, length(manifest_paths))",
  "manifest_current_sha[manifest_exists] <- vapply(",
  "  manifest_paths[manifest_exists],",
  "  artifact_sha256,",
  "  character(1)",
  ")",
  "manifest_current_bytes[manifest_exists] <- unname(",
  "  file.info(manifest_paths[manifest_exists])$size",
  ")",
  "manifest_audit <- immutable_reader_manifest |>",
  "  mutate(",
  "    path_exists = manifest_exists,",
  "    current_sha256 = manifest_current_sha,",
  "    current_bytes = manifest_current_bytes,",
  "    live_exact = .data$path_exists &",
  "      .data$current_sha256 == .data$sha256 &",
  "      .data$current_bytes == as.numeric(.data$bytes)",
  "  ) |>",
  "  left_join(",
  "    accepted_reader_transitions |>",
  "      transmute(",
  "        path = .data$path,",
  "        accepted_historical_sha256 = .data$sha256,",
  "        accepted_historical_bytes = as.numeric(.data$bytes),",
  "        accepted_live_sha256 = .data$current_sha256,",
  "        accepted_live_bytes = as.numeric(.data$current_bytes)",
  "      ),",
  "    by = \"path\",",
  "    relationship = \"many-to-one\"",
  "  ) |>",
  "  mutate(",
  "    accepted_transition = !.data$live_exact &",
  "      .data$path %in% expected_historical_paths &",
  "      .data$sha256 == .data$accepted_historical_sha256 &",
  "      as.numeric(.data$bytes) == .data$accepted_historical_bytes &",
  "      .data$current_sha256 == .data$accepted_live_sha256 &",
  "      .data$current_bytes == .data$accepted_live_bytes,",
  "    Status = case_when(",
  "      .data$live_exact ~ \"LIVE_EXACT\",",
  "      .data$accepted_transition ~ \"ACCEPTED_HISTORICAL_TO_LIVE\",",
  "      TRUE ~ \"FAIL\"",
  "    )",
  "  )",
  "observed_historical_paths <- manifest_audit |>",
  "  filter(!.data$live_exact) |>",
  "  pull(.data$path)",
  "stopifnot(",
  "  nrow(reader_manifest) == 108L,",
  "  nrow(immutable_reader_manifest) == 106L,",
  "  all(manifest_audit$path_exists),",
  "  sum(manifest_audit$Status == \"LIVE_EXACT\") == 87L,",
  paste0(
    "  sum(manifest_audit$Status == ",
    "\"ACCEPTED_HISTORICAL_TO_LIVE\") == 19L,"
  ),
  "  !any(manifest_audit$Status == \"FAIL\"),",
  paste0(
    "  identical(sort(observed_historical_paths), ",
    "sort(expected_historical_paths))"
  ),
  ")",
  "manifest_check <- tibble::tibble(",
  "  Check = c(",
  "    \"Immutable manifest paths exist\",",
  "    \"Live-exact identities\",",
  "    \"Accepted historical-to-live transitions\",",
  "    \"Exact historical path set\",",
  "    \"Manifest rows are unique\",",
  "    \"Recorded R version\"",
  "  ),",
  "  Observed = c(",
  paste0(
    "    paste0(sum(manifest_audit$path_exists), ",
    "\" / \" , nrow(manifest_audit)),"
  ),
  paste0(
    "    paste0(sum(manifest_audit$Status == ",
    "\"LIVE_EXACT\"), \" / 87\"),"
  ),
  "    paste0(",
  paste0(
    "      sum(manifest_audit$Status == ",
    "\"ACCEPTED_HISTORICAL_TO_LIVE\"),"
  ),
  "      \" / 19\"",
  "    ),",
  "    paste0(length(observed_historical_paths), \" / 19\"),",
  "    paste0(nrow(reader_manifest), \" / 108\"),",
  "    paste(sort(unique(reader_manifest$r_version)), collapse = \", \")",
  "  ),",
  "  Status = c(",
  "    if_else(all(manifest_audit$path_exists), \"PASS\", \"FAIL\"),",
  "    if_else(",
  "      sum(manifest_audit$Status == \"LIVE_EXACT\") == 87L,",
  "      \"PASS\",",
  "      \"FAIL\"",
  "    ),",
  "    if_else(",
  paste0(
    "      sum(manifest_audit$Status == ",
    "\"ACCEPTED_HISTORICAL_TO_LIVE\") == 19L,"
  ),
  "      \"PASS\",",
  "      \"FAIL\"",
  "    ),",
  "    if_else(",
  paste0(
    "      identical(sort(observed_historical_paths), ",
    "sort(expected_historical_paths)),"
  ),
  "      \"PASS\",",
  "      \"FAIL\"",
  "    ),",
  "    if_else(!anyDuplicated(reader_manifest$path), \"PASS\", \"FAIL\"),",
  "    if_else(all(reader_manifest$r_version == \"4.6.1\"), \"PASS\", \"FAIL\")",
  "  )",
  ")",
  "stopifnot(all(manifest_check$Status == \"PASS\"))"
)

qmd_rel <- "audit/hypotheses/H09/H09_analysis_preparation.qmd"
qmd_path <- file.path(root, qmd_rel)
qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
current_qmd_raw <- read_raw_file(qmd_path)
stopifnot(
  sha256_raw(current_qmd_raw) ==
    "286c391fb228268804ba199d38bd5341509b3a66d434e30aa09fc1007a19443e",
  length(current_qmd_raw) == 48400
)
label_line <- which(qmd_lines == "#| label: tbl-h09-prep-reader-manifest-check")
start <- which(qmd_lines == "mutable_records <- c(")
start <- start[start > label_line]
end <- which(qmd_lines == "stopifnot(all(manifest_check$Status == \"PASS\"))")
stopifnot(length(label_line) == 1L, length(start) == 1L, length(end) == 1L)
patched_lines <- c(
  qmd_lines[seq_len(start - 1L)],
  replacement,
  qmd_lines[seq.int(end + 1L, length(qmd_lines))]
)
reversed_lines <- c(
  patched_lines[seq_len(start - 1L)],
  qmd_lines[seq.int(start, end)],
  patched_lines[seq.int(start + length(replacement), length(patched_lines))]
)
stopifnot(identical(reversed_lines, qmd_lines))

probe_dir <- tempfile("h09-order57b-downstream.", tmpdir = "/private/tmp")
dir.create(probe_dir, recursive = TRUE)
on.exit(unlink(probe_dir, recursive = TRUE, force = TRUE), add = TRUE)
patched_qmd <- file.path(probe_dir, "H09_analysis_preparation.qmd")
purl_path <- file.path(probe_dir, "H09_analysis_preparation.R")
writeLines(patched_lines, patched_qmd, useBytes = TRUE)
prospective_sha <- sha256_file(patched_qmd)
prospective_bytes <- file_bytes(patched_qmd)
stopifnot(
  prospective_sha ==
    "394a976e52faf002cb2034a13353a053aae8bfda8942a79c2eb007017cae014f",
  prospective_bytes == 51736
)

invisible(knitr::purl(
  patched_qmd,
  output = purl_path,
  quiet = TRUE,
  documentation = 0L
))
invisible(parse(file = purl_path))
probe_env <- new.env(parent = globalenv())
sys.source(purl_path, envir = probe_env, chdir = FALSE)
probe_manifest <- get("manifest_audit", envir = probe_env, inherits = FALSE)
probe_checks <- get("manifest_check", envir = probe_env, inherits = FALSE)
stopifnot(
  nrow(probe_manifest) == 106L,
  sum(probe_manifest$Status == "LIVE_EXACT") == 87L,
  sum(probe_manifest$Status == "ACCEPTED_HISTORICAL_TO_LIVE") == 19L,
  !any(probe_manifest$Status == "FAIL"),
  all(probe_checks$Status == "PASS"),
  nrow(get("sample_plot_data", envir = probe_env, inherits = FALSE)) == 40L,
  get("execution", envir = probe_env, inherits = FALSE)$r_version == "4.6.1"
)

prospective_chunks <- extract_executable_r_chunks(patched_lines)
chunk_parse <- vapply(
  prospective_chunks,
  function(chunk)
    !inherits(try(parse(text = chunk), silent = TRUE), "try-error"),
  logical(1)
)
chunk_labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: ", patched_lines, value = TRUE)
)
failed_label_index <- match("tbl-h09-prep-reader-manifest-check", chunk_labels)
stopifnot(
  length(prospective_chunks) == 22L,
  all(chunk_parse),
  length(chunk_labels) == 22L,
  failed_label_index == 19L,
  length(chunk_labels) - failed_label_index == 3L
)

table_labels <- grep("^tbl-h09-", chunk_labels, value = TRUE)
figure_labels <- grep("^fig-h09-", chunk_labels, value = TRUE)
mermaid_count <- sum(trimws(patched_lines) == "flowchart TD")
patched_text <- paste(patched_lines, collapse = "\n")
relative_matches <- gregexpr(
  "\\]\\((\\.\\./[^)]+)\\)",
  patched_text,
  perl = TRUE
)
relative_values <- regmatches(patched_text, relative_matches)[[1L]]
relative_targets <- sub("^\\]\\(", "", relative_values)
relative_targets <- sub("\\)$", "", relative_targets)
relative_files <- sub("#.*$", "", relative_targets)
relative_exists <- file.exists(file.path(dirname(qmd_path), relative_files))
forbidden_calls <- c(
  "mgcv::gam",
  "mgcv::bam",
  "gam",
  "bam",
  "lme4::lmer",
  "lmer",
  "glmmTMB::glmmTMB",
  "glmmTMB",
  "nlme::lme",
  "lme",
  "stats::predict",
  "predict",
  "stats::simulate",
  "simulate",
  "boot::boot",
  "boot",
  "emmeans::emmeans",
  "emmeans",
  "h09_fit_model",
  "h09_fit_bundle",
  "h09_fit_models",
  "h09_model_diagnostics",
  "h09_residual_diagnostics",
  "h09_leave_one_site_out",
  "h09_participant_influence",
  "h09_photoperiod_sensitivity",
  "h09_participant_summary_sensitivity",
  "h09_ar1_sensitivity"
)
forbidden_observed <- intersect(
  executable_r_call_names(patched_lines),
  forbidden_calls
)
stopifnot(
  length(table_labels) == 19L,
  identical(figure_labels, "fig-h09-prep-sample-support"),
  mermaid_count == 1L,
  length(relative_targets) == 23L,
  length(unique(relative_targets)) == 22L,
  all(relative_exists),
  length(forbidden_observed) == 0L
)
add_check(
  "downstream replay",
  "all chunks including three later chunks",
  paste0(
    length(prospective_chunks),
    "/",
    length(chunk_labels) - failed_label_index
  ),
  "22/3 later",
  length(prospective_chunks) == 22L &&
    length(chunk_labels) - failed_label_index == 3L
)
add_check(
  "source contract",
  "endpoints and reader targets",
  paste(length(table_labels), length(figure_labels), mermaid_count, sep = "/"),
  "19/1/1",
  length(table_labels) == 19L &&
    length(figure_labels) == 1L &&
    mermaid_count == 1L
)

list_artifacts <- function(path) {
  if (!dir.exists(path)) return(character())
  list.files(
    path,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = FALSE,
    all.files = TRUE,
    no.. = TRUE
  )
}

h09_roots <- file.path(
  root,
  c(
    "scripts/hypotheses/H09",
    "tests/hypotheses/H09",
    "audit/hypotheses/H09",
    "artifacts/06_model_data/H09",
    "artifacts/07_models/H09",
    "artifacts/08_diagnostics/H09",
    "artifacts/09_tables/H09",
    "artifacts/10_figures/H09",
    "artifacts/11_source_data/H09",
    "artifacts/12_manifests/H09"
  )
)
h09_files <- unlist(lapply(h09_roots, list_artifacts), use.names = FALSE)
page_assets <- list_artifacts(file.path(
  root,
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation_files"
))
decision_files <- file.path(
  root,
  c(
    "audit/decisions/answer_in_brief_callout.md",
    "audit/decisions/bootstrap_execution_policy.md",
    "audit/decisions/figure_readability_and_layout.md",
    "audit/decisions/gap_timing_unaware_dataset_terminology.md",
    "audit/decisions/hypothesis_preparation_provenance_companions.md",
    "audit/decisions/model_reporting.md",
    "audit/decisions/p_value_display_conventions.md",
    "audit/decisions/paired_placement_comparison_display.md",
    "audit/decisions/placement_decision.md",
    "audit/decisions/reader_facing_symlog_scale.md",
    "audit/decisions/site_display_conventions.md"
  )
)
supporting_files <- file.path(
  root,
  c(
    "AGENTS.md",
    "renv.lock",
    "_quarto.yml",
    "_quarto-nathealth.yml",
    "notebooks/hypotheses/H09.qmd",
    "_build/nathealth/notebooks/hypotheses/H09.html",
    "config/metric_display_registry.csv",
    "config/site_display_registry.csv",
    "audit/evidence/preregistration_contract.md",
    "audit/hypotheses/H03-H11_gated_workflow.qmd",
    "audit/hypotheses/H09-H11_migration_map.md",
    "scripts/pipeline/paths_io.R",
    "scripts/pipeline/p_value_display.R",
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
  )
)
helper_manifest_rel <-
  "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv"
helper_files <- unique(c(
  qmd_path,
  file.path(
    root,
    "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html"
  ),
  file.path(
    root,
    "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd"
  ),
  file.path(root, "notebooks/hypotheses/H09.qmd"),
  file.path(root, "_build/nathealth/notebooks/hypotheses/H09.html"),
  file.path(root, "_quarto-nathealth.yml"),
  h09_files,
  page_assets,
  decision_files,
  supporting_files
))
helper_files <- helper_files[
  !grepl(
    "audit/handoffs/H09_(?:worker_handoff|shared_change_request)\\.md$",
    helper_files,
    perl = TRUE
  )
]
helper_files <- setdiff(helper_files, file.path(root, helper_manifest_rel))
helper_files <- helper_files[
  file.exists(helper_files) & !dir.exists(helper_files)
]
helper_relative <- substring(
  sort(unique(normalizePath(helper_files, winslash = "/", mustWork = TRUE))),
  nchar(root) + 2L
)
stopifnot(
  length(helper_relative) == 554L,
  !anyDuplicated(helper_relative),
  !helper_manifest_rel %in% helper_relative,
  length(page_assets) == 0L
)
helper_inventory <- tibble::tibble(
  path = helper_relative,
  current_sha256 = vapply(
    file.path(root, helper_relative),
    sha256_file,
    character(1)
  ),
  current_bytes = file_bytes(file.path(root, helper_relative)),
  expected_members_before_render = 554L,
  expected_target_assets_after_render = 1L,
  expected_manifest_rows_after_render = 555L
)
add_check(
  "helper replay",
  "prospective non-circular inventory",
  length(helper_relative),
  "554 before render and 555 after one target asset",
  length(helper_relative) == 554L && length(page_assets) == 0L
)

held_html_rel <- paste0(
  "_build/nathealth/audit/hypotheses/H09/",
  "H09_analysis_preparation.html"
)
held_html <- file.path(root, held_html_rel)
stopifnot(
  sha256_file(held_html) ==
    "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
  file_bytes(held_html) == 593181
)
semantic_root <- tempfile("h09-order57b-semantic.", tmpdir = "/private/tmp")
semantic_audit_dir <- tempfile(
  "h09-order57b-semantic-audit.",
  tmpdir = "/private/tmp"
)
dir.create(file.path(semantic_root, dirname(held_html_rel)), recursive = TRUE)
dir.create(
  file.path(semantic_root, "scripts/report_harmonization"),
  recursive = TRUE
)
dir.create(semantic_audit_dir, recursive = TRUE)
on.exit(unlink(semantic_root, recursive = TRUE, force = TRUE), add = TRUE)
on.exit(unlink(semantic_audit_dir, recursive = TRUE, force = TRUE), add = TRUE)
semantic_target <- file.path(semantic_root, held_html_rel)
stopifnot(
  file.copy(held_html, semantic_target),
  file.copy(
    file.path(root, "_quarto-nathealth.yml"),
    file.path(semantic_root, "_quarto-nathealth.yml")
  ),
  file.copy(
    file.path(root, "scripts/report_harmonization/repair_gt_html_semantics.R"),
    file.path(
      semantic_root,
      "scripts/report_harmonization/repair_gt_html_semantics.R"
    )
  )
)
semantic_pre_raw <- read_raw_file(semantic_target)
wrapper_env <- new.env(parent = globalenv())
sys.source(
  file.path(
    root,
    "scripts/report_harmonization/post_render_gt_html_semantics.R"
  ),
  envir = wrapper_env
)
semantic_summary <- local({
  previous_dir <- getwd()
  on.exit(setwd(previous_dir), add = TRUE)
  setwd(semantic_root)
  wrapper_env$run_post_render_gt_html_semantics(
    environment = list(
      QUARTO_PROJECT_DIR = semantic_root,
      QUARTO_PROJECT_OUTPUT_DIR = "_build/nathealth",
      QUARTO_PROJECT_OUTPUT_FILES = held_html_rel,
      GT_HTML_SEMANTIC_AUDIT_DIR = semantic_audit_dir
    ),
    project_dir = semantic_root
  )
})
stopifnot(
  nrow(semantic_summary) == 1L,
  semantic_summary$disposition == "REPAIRED",
  semantic_summary$table_count == 19L,
  semantic_summary$id_count == 102L,
  semantic_summary$headers_count == 588L,
  semantic_summary$total_substitutions == 690L
)
ledger_path <- list.files(
  semantic_audit_dir,
  pattern = "ledger[.]csv$",
  full.names = TRUE
)
stopifnot(length(ledger_path) == 1L)
ledger <- utils::read.csv(ledger_path, check.names = FALSE)
semantic_post_raw <- read_raw_file(semantic_target)
engine_env <- new.env(parent = globalenv())
sys.source(
  file.path(root, "scripts/report_harmonization/repair_gt_html_semantics.R"),
  envir = engine_env
)
semantic_reversed_raw <- engine_env$apply_raw_replacements(
  semantic_post_raw,
  ledger,
  reverse = TRUE
)
stopifnot(
  nrow(ledger) == 690L,
  identical(semantic_reversed_raw, semantic_pre_raw),
  sha256_raw(semantic_reversed_raw) ==
    "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05"
)
semantic_document <- xml2::read_html(rawToChar(semantic_post_raw))
main <- xml2::xml_find_all(
  semantic_document,
  "//main[@id='quarto-document-content']"
)
tables <- xml2::xml_find_all(
  main,
  paste0(
    ".//table[contains(concat(' ', normalize-space(@class), ' '),",
    " ' gt_table ')]"
  )
)
ids <- xml2::xml_attr(xml2::xml_find_all(semantic_document, ".//*[@id]"), "id")
ids <- ids[!is.na(ids) & nzchar(ids)]
header_values <- xml2::xml_attr(
  xml2::xml_find_all(tables, ".//*[@headers]"),
  "headers"
)
header_tokens <- unlist(
  strsplit(header_values, "[[:space:]]+"),
  use.names = FALSE
)
stopifnot(
  length(main) == 1L,
  length(tables) == 19L,
  !anyDuplicated(ids),
  all(header_tokens %in% ids)
)
semantic_probe <- tibble::tibble(
  disposition = semantic_summary$disposition,
  tables = semantic_summary$table_count,
  id_substitutions = semantic_summary$id_count,
  headers_substitutions = semantic_summary$headers_count,
  total_substitutions = semantic_summary$total_substitutions,
  ledger_rows = nrow(ledger),
  exact_reverse = identical(semantic_reversed_raw, semantic_pre_raw),
  pre_sha256 = sha256_raw(semantic_pre_raw),
  post_sha256 = sha256_raw(semantic_post_raw),
  status = "PASS"
)
add_check(
  "semantic replay",
  "held-page repair and exact reverse",
  paste(
    semantic_summary$table_count,
    semantic_summary$id_count,
    semantic_summary$headers_count,
    nrow(ledger),
    sep = "/"
  ),
  "19/102/588/690",
  identical(semantic_reversed_raw, semantic_pre_raw)
)

verify_inventory <- function(name, expected_rows) {
  inventory <- utils::read.csv(
    file.path(stop_dir, name),
    check.names = FALSE
  )
  files <- file.path(root, inventory$relative_path)
  exists <- file.exists(files) & !dir.exists(files)
  current_sha <- rep(NA_character_, nrow(inventory))
  current_bytes <- rep(NA_real_, nrow(inventory))
  current_sha[exists] <- vapply(files[exists], sha256_file, character(1))
  current_bytes[exists] <- file_bytes(files[exists])
  exact <- exists &
    current_sha == inventory$sha256 &
    current_bytes == as.numeric(inventory$bytes)
  stopifnot(
    nrow(inventory) == expected_rows,
    !anyDuplicated(inventory$relative_path),
    all(exact)
  )
  tibble::tibble(
    inventory = name,
    rows = nrow(inventory),
    exact_rows = sum(exact),
    status = "PASS"
  )
}

preservation <- bind_rows(
  verify_inventory("build_inventory_postfailure.csv", 851L),
  verify_inventory("protected_inventory_postfailure.csv", 545L),
  verify_inventory("source_side_support_tree_postfailure.csv", 16L)
)
stopifnot(all(preservation$status == "PASS"))
add_check(
  "preservation",
  "build, protected, and source-side baselines",
  paste(preservation$exact_rows, collapse = "/"),
  "851/545/16",
  all(preservation$status == "PASS")
)

source_replay <- tibble::tibble(
  current_qmd_sha256 = sha256_raw(current_qmd_raw),
  current_qmd_bytes = length(current_qmd_raw),
  prospective_qmd_sha256 = prospective_sha,
  prospective_qmd_bytes = prospective_bytes,
  exact_reverse = identical(reversed_lines, qmd_lines),
  chunks = length(prospective_chunks),
  chunks_after_stopped_table = length(chunk_labels) - failed_label_index,
  tables = length(table_labels),
  figures = length(figure_labels),
  top_down_mermaid = mermaid_count,
  relative_link_occurrences = length(relative_targets),
  unique_relative_targets = length(unique(relative_targets)),
  forbidden_scientific_calls = length(forbidden_observed),
  status = "PASS"
)

write_audit(
  owner_manifest_audit,
  "report018_h09_order57a_stopped_manifest_independent_audit.csv"
)
write_audit(
  classification,
  "report018_h09_order57a_stage3_transition_classification.csv"
)
write_audit(
  source_replay,
  "report018_h09_order57b_downstream_source_replay.csv"
)
write_audit(
  helper_inventory,
  "report018_h09_order57b_helper_inventory_replay.csv"
)
write_audit(
  semantic_probe,
  "report018_h09_order57b_semantic_probe.csv"
)
write_audit(
  preservation,
  "report018_h09_order57b_preservation_replay.csv"
)

stopifnot(all(checks$status == "PASS"))
write_audit(
  checks,
  "report018_h09_order57a_downstream_independent_verification.csv"
)

cat(sprintf(
  paste0(
    "REPORT018_H09_ORDER57A_DOWNSTREAM=PASS stop=58/58 verification=17/17 ",
    "stage3=87+19 authority=19/19 chunks=22 later=3 ",
    "endpoints=19+1+1 links=23/22 helper=554->555 ",
    "semantic=19/102/588/690 preservation=851/545/16 R=%s\n"
  ),
  as.character(getRversion())
))
