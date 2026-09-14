#!/usr/bin/env Rscript

# Independently audit the REPORT-018 H09 order-57b pre-render stop and the
# exact order-specific verifier replay completed with narrowly elevated,
# read-only process inspection.

Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE, warn = 2, lifecycle_verbosity = "quiet")

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H09 order-57b environment audit requires R 4.6.1.", call. = FALSE)
}

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv(
    "NATHEALTH_PROJECT_ROOT",
    unset = paste0(
      "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/",
      "WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
    )
  ),
  winslash = "/",
  mustWork = TRUE
)
owner_dir <- normalizePath(
  Sys.getenv(
    "H09_ORDER57B_STOP_DIR",
    unset = "/private/tmp/h09-order57b-working.J2KttI"
  ),
  winslash = "/",
  mustWork = TRUE
)
replay_dir <- normalizePath(
  Sys.getenv(
    "H09_ORDER57B_REPLAY_DIR",
    unset = "/private/tmp/h09-order57c-preflight.HQYGiS"
  ),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256")
}

file_bytes <- function(path) unname(file.info(path)$size)

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
      observed = paste(observed, collapse = "/"),
      expected = paste(expected, collapse = "/"),
      status = if (isTRUE(pass)) "PASS" else "FAIL"
    )
  )
}

direct_pins <- tibble::tribble(
  ~path,
  ~sha256,
  ~bytes,
  file.path(owner_dir, "ORDER57B_FAIL_CLOSED.md"),
  "4e745700f8939559bb04bdc9cf2cede0439d779361e4904c39c9e260c260b33c",
  5555,
  file.path(owner_dir, "order57b_fail_closed_evidence_manifest.csv"),
  "3d310e931c7210adfa7ea0717b4398b40894e41d2177e349d5f133614ae4d10b",
  11610,
  file.path(owner_dir, "verify_order57b_h09_companion.R"),
  "a6c418c70216227dd335e7de850c119db13f7bfda7f0340f88c7d81f0ecc99fa",
  37584
)
direct_exact <-
  file.exists(direct_pins$path) &
  !dir.exists(direct_pins$path) &
  vapply(direct_pins$path, sha256_file, character(1)) == direct_pins$sha256 &
  file_bytes(direct_pins$path) == direct_pins$bytes
stopifnot(all(direct_exact))
add_check(
  "owner stop",
  "direct owner identities",
  paste0(sum(direct_exact), "/3"),
  "3/3",
  all(direct_exact)
)

owner_manifest_path <- direct_pins$path[[2L]]
owner_manifest <- utils::read.csv(owner_manifest_path, check.names = FALSE)
required_manifest_columns <- c(
  "path",
  "observed_path",
  "role",
  "sha256",
  "bytes",
  "r_version"
)
stopifnot(
  nrow(owner_manifest) == 42L,
  all(required_manifest_columns %in% names(owner_manifest)),
  !anyDuplicated(owner_manifest$path),
  !owner_manifest_path %in% owner_manifest$observed_path,
  all(owner_manifest$r_version == "4.6.1")
)
owner_exists <- file.exists(owner_manifest$observed_path) &
  !dir.exists(owner_manifest$observed_path)
owner_observed_sha <- rep(NA_character_, nrow(owner_manifest))
owner_observed_bytes <- rep(NA_real_, nrow(owner_manifest))
owner_observed_sha[owner_exists] <- vapply(
  owner_manifest$observed_path[owner_exists],
  sha256_file,
  character(1)
)
owner_observed_bytes[owner_exists] <- file_bytes(
  owner_manifest$observed_path[owner_exists]
)
owner_audit <- owner_manifest |>
  mutate(
    observed_sha256 = owner_observed_sha,
    observed_bytes = owner_observed_bytes,
    status = if_else(
      owner_exists &
        .data$sha256 == .data$observed_sha256 &
        as.numeric(.data$bytes) == .data$observed_bytes,
      "PASS",
      "FAIL"
    )
  )
stopifnot(all(owner_audit$status == "PASS"))
add_check(
  "owner stop",
  "42-row non-circular evidence manifest",
  paste0(sum(owner_audit$status == "PASS"), "/42"),
  "42/42",
  all(owner_audit$status == "PASS")
)

execution_gate <- utils::read.csv(
  file.path(owner_dir, "execution_gate.csv"),
  check.names = FALSE
)
stopifnot(
  nrow(execution_gate) == 8L,
  identical(
    execution_gate$phase,
    c(
      "dispatch pre-edit verification",
      "accepted independent downstream checker",
      "authorized source replacement",
      "complete pre-render verifier",
      "H09 companion Quarto render",
      "dedicated preparation-manifest helper",
      "post-render verifier",
      "secure loopback visual QA"
    )
  ),
  identical(
    as.integer(execution_gate$invocation_count),
    c(1L, 1L, 1L, 1L, 0L, 0L, 0L, 0L)
  ),
  identical(execution_gate$status[[4L]], "FAIL_CLOSED"),
  all(execution_gate$status[5:8] == "NOT_RUN")
)
add_check(
  "invocations",
  "render allowance unconsumed",
  paste(execution_gate$invocation_count[4:8], collapse = "/"),
  "1/0/0/0/0",
  identical(
    as.integer(execution_gate$invocation_count[4:8]),
    c(1L, 0L, 0L, 0L, 0L)
  )
)

current_pins <- tibble::tribble(
  ~path,
  ~sha256,
  ~bytes,
  "audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "394a976e52faf002cb2034a13353a053aae8bfda8942a79c2eb007017cae014f",
  51736,
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
  "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
  593181,
  "notebooks/hypotheses/H09.qmd",
  "c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6",
  36970,
  "_build/nathealth/notebooks/hypotheses/H09.html",
  "901fd63b45182be70ef77166c418633220a7226d86f52e14d1c79afbfc7cdd16",
  244127,
  "artifacts/12_manifests/H09/H09_stage3_artifacts.csv",
  "0103aad8bf3b2424358fc139b85b95564054745b180a80d1e12c27ff72e1bef2",
  24678,
  "_quarto-nathealth.yml",
  "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  7480,
  "renv.lock",
  "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
  603493
)
current_files <- file.path(root, current_pins$path)
current_exact <-
  file.exists(current_files) &
  !dir.exists(current_files) &
  vapply(current_files, sha256_file, character(1)) == current_pins$sha256 &
  file_bytes(current_files) == current_pins$bytes
stopifnot(all(current_exact))
add_check(
  "preservation",
  "current source, result, HTML, manifest, profile, and lock pins",
  paste0(sum(current_exact), "/7"),
  "7/7",
  all(current_exact)
)

replay_files <- list.files(
  replay_dir,
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = FALSE,
  all.files = TRUE,
  no.. = TRUE
)
replay_inventory <- tibble::tibble(
  relative_path = substring(replay_files, nchar(replay_dir) + 2L),
  sha256 = vapply(replay_files, sha256_file, character(1)),
  bytes = file_bytes(replay_files)
) |>
  arrange(.data$relative_path)
stopifnot(
  nrow(replay_inventory) == 24L,
  !anyDuplicated(replay_inventory$relative_path)
)

replay_verification <- utils::read.csv(
  file.path(replay_dir, "verification_pre.csv"),
  check.names = FALSE
)
replay_process <- utils::read.csv(
  file.path(replay_dir, "process_audit_pre.csv"),
  check.names = FALSE
)
replay_versions <- utils::read.csv(
  file.path(replay_dir, "versions_pre.csv"),
  check.names = FALSE
)
stopifnot(
  nrow(replay_verification) == 12L,
  all(replay_verification$status == "PASS"),
  nrow(replay_process) == 1L,
  replay_process$observed == "none",
  replay_process$competing_processes == 0L,
  replay_process$status == "PASS",
  nrow(replay_versions) == 2L,
  identical(replay_versions$observed, c("4.6.1", "1.9.37")),
  all(replay_versions$status == "PASS")
)
add_check(
  "elevated replay",
  "unchanged complete verifier and process inventory",
  paste0(nrow(replay_verification), "/", replay_process$competing_processes),
  "12/0",
  all(replay_verification$status == "PASS") &&
    replay_process$competing_processes == 0L
)

invariant_names <- c(
  "build_baseline_audit_pre.csv",
  "build_inventory_prerender.csv",
  "dispatch_audit_pre.csv",
  "H09_analysis_preparation.pre.R",
  "H09_analysis_preparation.reversed.pre.qmd",
  "helper_inventory_pre.csv",
  "independent_acceptance_audit_pre.csv",
  "owner_stop_audit_pre.csv",
  "owner_stop_checks_pre.csv",
  "protected_audit_pre.csv",
  "semantic_audit_pre.csv",
  "source_execution_audit_pre.csv",
  "source_link_audit_pre.csv",
  "source_reverse_proof_pre.csv",
  "source_side_support_audit_pre.csv",
  "transition_authority_pre.csv"
)
owner_invariant <- file.path(owner_dir, invariant_names)
replay_invariant <- file.path(replay_dir, invariant_names)
invariant_comparison <- tibble::tibble(
  path = invariant_names,
  owner_sha256 = vapply(owner_invariant, sha256_file, character(1)),
  replay_sha256 = vapply(replay_invariant, sha256_file, character(1)),
  owner_bytes = file_bytes(owner_invariant),
  replay_bytes = file_bytes(replay_invariant)
) |>
  mutate(
    exact = .data$owner_sha256 == .data$replay_sha256 &
      .data$owner_bytes == .data$replay_bytes,
    status = if_else(.data$exact, "PASS", "FAIL")
  )
stopifnot(nrow(invariant_comparison) == 16L, all(invariant_comparison$exact))
add_check(
  "elevated replay",
  "owner and independent invariant evidence",
  paste0(sum(invariant_comparison$exact), "/16"),
  "16/16",
  all(invariant_comparison$exact)
)

gate_files <- list(
  build = file.path(replay_dir, "build_baseline_audit_pre.csv"),
  protected = file.path(replay_dir, "protected_audit_pre.csv"),
  support = file.path(replay_dir, "source_side_support_audit_pre.csv"),
  helper = file.path(replay_dir, "helper_inventory_pre.csv"),
  source = file.path(replay_dir, "source_execution_audit_pre.csv"),
  semantic = file.path(replay_dir, "semantic_audit_pre.csv"),
  transitions = file.path(replay_dir, "transition_authority_pre.csv")
)
gate_data <- lapply(gate_files, utils::read.csv, check.names = FALSE)
stopifnot(
  nrow(gate_data$build) == 851L,
  all(gate_data$build$status == "PASS"),
  nrow(gate_data$protected) == 545L,
  all(gate_data$protected$status == "PASS"),
  nrow(gate_data$support) == 16L,
  all(gate_data$support$status == "PASS"),
  nrow(gate_data$helper) == 554L,
  all(gate_data$helper$status == "PASS"),
  nrow(gate_data$source) == 1L,
  gate_data$source$status == "PASS",
  nrow(gate_data$semantic) == 1L,
  gate_data$semantic$status == "PASS",
  nrow(gate_data$transitions) == 19L,
  all(gate_data$transitions$authority_row_exact),
  all(gate_data$transitions$disposition == "ACCEPTED_HISTORICAL_TO_LIVE")
)
add_check(
  "complete gate",
  "build, protected, support, helper, source, semantic, and transitions",
  "851/545/16/554/1/1/19",
  "851/545/16/554/1/1/19",
  TRUE
)

output_dir <- file.path(root, "audit/report_harmonization")
utils::write.csv(
  owner_audit,
  file.path(
    output_dir,
    "report018_h09_order57b_environment_stop_owner_manifest_audit.csv"
  ),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  replay_inventory,
  file.path(
    output_dir,
    "report018_h09_order57c_environment_preflight_inventory.csv"
  ),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  invariant_comparison,
  file.path(
    output_dir,
    "report018_h09_order57c_environment_preflight_invariant_comparison.csv"
  ),
  row.names = FALSE,
  na = ""
)
process_record <- tibble::tibble(
  probe = "/bin/ps -Ao pid=,command=",
  access = "narrowly elevated read-only process inventory",
  observed = replay_process$observed,
  competing_processes = replay_process$competing_processes,
  status = replay_process$status,
  source_sha256 = sha256_file(file.path(replay_dir, "process_audit_pre.csv")),
  source_bytes = file_bytes(file.path(replay_dir, "process_audit_pre.csv"))
)
utils::write.csv(
  process_record,
  file.path(
    output_dir,
    "report018_h09_order57c_elevated_process_inventory.csv"
  ),
  row.names = FALSE,
  na = ""
)

stopifnot(all(checks$status == "PASS"))
utils::write.csv(
  checks,
  file.path(
    output_dir,
    "report018_h09_order57b_environment_stop_independent_verification.csv"
  ),
  row.names = FALSE,
  na = ""
)

cat(sprintf(
  paste0(
    "REPORT018_H09_ORDER57B_ENVIRONMENT_STOP=PASS owner=42/42 ",
    "direct=3/3 invocations=1/0/0/0/0 pins=7/7 replay=12/12 ",
    "process=0 invariants=16/16 gates=851/545/16/554/1/1/19 R=%s\n"
  ),
  as.character(getRversion())
))
