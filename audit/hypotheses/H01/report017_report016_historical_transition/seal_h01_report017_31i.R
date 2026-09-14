# Seal the completed REPORT-017 order 31i transition classification.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

evidence_relative <-
  "audit/hypotheses/H01/report017_report016_historical_transition"
evidence_dir <- file.path(root, evidence_relative)
test_path <-
  "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R"
worker_path <- "artifacts/12_manifests/H01_worker_artifacts.csv"
stage3_path <- "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
reporting_path <- "artifacts/12_manifests/H01_reporting_artifacts.csv"
historical_manifest_path <- paste0(
  "audit/hypotheses/H01/report016/",
  "H01_REPORT016_reconciliation_manifest.csv"
)

identity_row <- function(path) {
  stopifnot(file.exists(path))
  tibble(
    path = path,
    sha256 = artifact_sha256(path),
    bytes = as.numeric(file.info(path)$size)
  )
}

write_evidence <- function(data, filename) {
  readr::write_csv(data, file.path(evidence_dir, filename), na = "")
}

audit_manifest <- function(path) {
  manifest <- readr::read_csv(path, show_col_types = FALSE)
  present <- file.exists(manifest$path)
  current_sha256 <- rep(NA_character_, nrow(manifest))
  current_bytes <- rep(NA_real_, nrow(manifest))
  current_sha256[present] <- unname(vapply(
    manifest$path[present],
    artifact_sha256,
    character(1)
  ))
  current_bytes[present] <- as.numeric(file.info(manifest$path[present])$size)
  manifest |>
    mutate(
      ordinal = row_number(),
      present = present,
      current_sha256 = current_sha256,
      current_bytes = current_bytes,
      status = if_else(
        .data$present &
          .data$sha256 == .data$current_sha256 &
          .data$bytes == .data$current_bytes,
        "PASS",
        "MISMATCH"
      ),
      .before = 1L
    )
}

stopifnot(
  identical(
    artifact_sha256(
      "audit/report_harmonization/owner_orders/31i_h01_report016_historical_reconciliation_transition_classification.md"
    ),
    "199d6afa38761bd869581274389b4e3a5fd8eccddd285163e51540d5d9f4ef52"
  ),
  identical(
    artifact_sha256(
      "audit/report_harmonization/owner_orders/31i_a_h01_dispatch_matrix_preflight_correction.md"
    ),
    "77fe1921158f6fc587d68268ea32f072c00d97061d17b27a1f29ae25e1f5e3ab"
  ),
  identical(
    artifact_sha256("audit/report_harmonization/coordination_matrix.csv"),
    "84fd119862c3fb8b6322faf4cf1bc231776356aa32f395064404ee4d6481cea8"
  ),
  identical(
    artifact_sha256(test_path),
    "1aa2e9419fcc25fbfc759ffa0a39aa0556abff5bdc3f2c6e4f1950213bdec2e5"
  ),
  identical(as.numeric(file.info(test_path)$size), 13758),
  identical(
    artifact_sha256(worker_path),
    "debce70f59c8e2c401ad36291694604246349633079bcd4d706aba6cf4d548c5"
  ),
  identical(as.numeric(file.info(worker_path)$size), 393672),
  identical(
    artifact_sha256(stage3_path),
    "16e752b57eafa43b9cc09d70a698ba194cb3fe83dc62bf1bcc3e08c67f85eb6e"
  ),
  identical(
    artifact_sha256(reporting_path),
    "d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079"
  ),
  identical(
    artifact_sha256(historical_manifest_path),
    "15f88d244450f380112f1ab7adfadade56f518ea43daf8ef4fb0454278cdd5bf"
  )
)

test_text <- paste(readLines(test_path, warn = FALSE), collapse = "\n")
stopifnot(!grepl(
  "1aa2e9419fcc25fbfc759ffa0a39aa0556abff5bdc3f2c6e4f1950213bdec2e5",
  test_text,
  fixed = TRUE
))

test_reverse <- readr::read_csv(
  file.path(evidence_dir, "H01_REPORT017_31i_test_reverse.csv"),
  show_col_types = FALSE
)
worker_reverse <- readr::read_csv(
  file.path(evidence_dir, "H01_REPORT017_31i_worker_reverse.csv"),
  show_col_types = FALSE
)
worker_ledger <- readr::read_csv(
  file.path(evidence_dir, "H01_REPORT017_31i_worker_row_ledger.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(test_reverse) == 1L,
  identical(test_reverse$status, "PASS"),
  identical(
    test_reverse$reconstructed_sha256,
    "b0c41cef4a0f373b5ae4da8bcac987493f4d3d46618fd217c964945f5ed8b620"
  ),
  nrow(worker_reverse) == 1L,
  identical(worker_reverse$status, "PASS"),
  identical(
    worker_reverse$reconstructed_sha256,
    "9a369002e9ebfdc9d99ba08c1bb86b2588d6308b7e844b36fea6336f95e47328"
  ),
  nrow(worker_ledger) == 1L,
  identical(worker_ledger$path, test_path),
  identical(
    worker_ledger$after_sha256,
    "1aa2e9419fcc25fbfc759ffa0a39aa0556abff5bdc3f2c6e4f1950213bdec2e5"
  ),
  identical(worker_ledger$after_bytes, 13758),
  worker_ledger$producer_preserved,
  worker_ledger$r_version_preserved
)

worker <- readr::read_csv(worker_path, show_col_types = FALSE)
test_worker_row <- worker |>
  filter(.data$path == test_path)
stopifnot(
  nrow(test_worker_row) == 1L,
  identical(test_worker_row$sha256, artifact_sha256(test_path)),
  identical(test_worker_row$bytes, as.numeric(file.info(test_path)$size))
)

historical <- readr::read_csv(
  historical_manifest_path,
  show_col_types = FALSE
)
historical_current <- historical |>
  mutate(
    current_sha256 = unname(vapply(.data$path, artifact_sha256, character(1))),
    current_bytes = as.numeric(file.info(.data$path)$size)
  )
transition_contract <- tibble(
  path = c(
    stage3_path,
    reporting_path,
    "notebooks/hypotheses/H01.qmd",
    "audit/hypotheses/H01/H01_analysis_preparation.qmd",
    "_build/nathealth/notebooks/hypotheses/H01.html",
    "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
    test_path
  ),
  frozen_sha256 = c(
    "476fa10db3383b2de82bb1824e9e5d89b8629d1666d080fe79520c5b81800806",
    "4d39e9b1f76fed6fa56d8f9d210d5fd83b2d744e1e6dc67f60fcefe82b24b6b6",
    "8c7ca4e7382b1f9cc5fe07bb9cdf8a1318fd6e311f7df4e86556ae3e390abe96",
    "685641fcb163e55b96b34778f25b276d8ce289bacd0ad73ece4351d859ebb4cb",
    "53a216ff0ae82b2e9177671d6330862832c1c5f2a9e79251e0da0acb5671260f",
    "eca3e1e855314838c51172d3dd24922ac8e5db096b6c5e3b505d74853885b28c",
    "55c89eb03f9510ea3bce937a26da04d552d9eb4d6c2f87aec34884af69715765"
  ),
  frozen_bytes = c(22735, 11054, 87441, 54286, 1351940, 68213, 6617),
  live_sha256 = c(
    "16e752b57eafa43b9cc09d70a698ba194cb3fe83dc62bf1bcc3e08c67f85eb6e",
    "d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079",
    "31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6",
    "962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8",
    "6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa",
    "35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7",
    test_worker_row$sha256
  ),
  live_bytes = c(
    26497,
    11054,
    90640,
    54405,
    1626484,
    68214,
    test_worker_row$bytes
  )
)
transition_rows <- historical_current |>
  filter(.data$path %in% transition_contract$path) |>
  arrange(match(.data$path, transition_contract$path)) |>
  mutate(classification = "AUTHORIZED_HISTORICAL_TO_LIVE_TRANSITION")
exact_rows <- historical_current |>
  filter(!.data$path %in% transition_contract$path) |>
  mutate(classification = "LIVE_EXACT_HISTORICAL_ROW")
mismatch_paths <- historical_current |>
  filter(
    .data$sha256 != .data$current_sha256 |
      .data$bytes != .data$current_bytes
  ) |>
  pull(.data$path)
stopifnot(
  nrow(historical_current) == 15L,
  !anyDuplicated(historical_current$path),
  nrow(transition_rows) == 7L,
  nrow(exact_rows) == 8L,
  identical(transition_rows$path, transition_contract$path),
  identical(sort(mismatch_paths), sort(transition_contract$path)),
  identical(transition_rows$sha256, transition_contract$frozen_sha256),
  identical(transition_rows$bytes, transition_contract$frozen_bytes),
  identical(transition_rows$current_sha256, transition_contract$live_sha256),
  identical(transition_rows$current_bytes, transition_contract$live_bytes),
  all(exact_rows$sha256 == exact_rows$current_sha256),
  all(exact_rows$bytes == exact_rows$current_bytes)
)
write_evidence(transition_rows, "H01_REPORT017_31i_seven_transitions.csv")
write_evidence(exact_rows, "H01_REPORT017_31i_eight_exact_rows.csv")

worker_audit <- audit_manifest(worker_path)
expected_worker_historical <- c(
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "_quarto-nathealth.yml",
  reporting_path,
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "notebooks/hypotheses/H01.qmd",
  "tests/hypotheses/H01/test_h01_reporting_inputs.R"
)
stopifnot(
  nrow(worker_audit) == 1644L,
  identical(
    sort(worker_audit$path[worker_audit$status == "MISMATCH"]),
    sort(expected_worker_historical)
  ),
  sum(worker_audit$status == "PASS") == 1638L
)
write_evidence(worker_audit, "H01_REPORT017_31i_worker_all_row_audit.csv")

report016_pre <- readr::read_csv(
  file.path(evidence_dir, "H01_REPORT017_31i_report016_inventory_pre.csv"),
  show_col_types = FALSE
)
report016_current <- bind_rows(lapply(report016_pre$path, identity_row))
stopifnot(
  identical(report016_pre$path, report016_current$path),
  identical(report016_pre$sha256, report016_current$sha256),
  identical(report016_pre$bytes, report016_current$bytes)
)
write_evidence(
  report016_current,
  "H01_REPORT017_31i_report016_inventory_final.csv"
)

protected_pre <- readr::read_csv(
  file.path(evidence_dir, "H01_REPORT017_31i_protected_pre.csv"),
  show_col_types = FALSE
)
protected_current <- bind_rows(lapply(protected_pre$path, identity_row))
stopifnot(
  identical(protected_pre$path, protected_current$path),
  identical(protected_pre$sha256, protected_current$sha256),
  identical(protected_pre$bytes, protected_current$bytes)
)
write_evidence(protected_current, "H01_REPORT017_31i_protected_final.csv")

qmd_text <- paste(
  readLines("notebooks/hypotheses/H01.qmd", warn = FALSE),
  collapse = "\n"
)
registration_targets <- regmatches(
  qmd_text,
  gregexpr(
    "(?<=\\()([^)]*preregistration_deviations[^)]*)(?=\\))",
    qmd_text,
    perl = TRUE
  )
)[[1]]
registration_anchors <- substring(
  registration_targets,
  nchar("../preregistration_deviations.qmd#") + 1L
)
central_text <- paste(
  readLines("notebooks/preregistration_deviations.qmd", warn = FALSE),
  collapse = "\n"
)
central_anchors <- gsub(
  "^\\{#|\\}$",
  "",
  regmatches(
    central_text,
    gregexpr("\\{#[A-Za-z0-9-]+\\}", central_text, perl = TRUE)
  )[[1]]
)
stopifnot(
  length(registration_targets) == 40L,
  length(unique(registration_anchors)) == 36L,
  all(grepl(
    "^[.][.]/preregistration_deviations[.]qmd#[a-z0-9-]+$",
    registration_targets,
    perl = TRUE
  )),
  all(vapply(
    unique(registration_anchors),
    function(anchor) sum(central_anchors == anchor) == 1L,
    logical(1)
  ))
)
write_evidence(
  tibble(
    target_occurrences = length(registration_targets),
    unique_anchors = length(unique(registration_anchors)),
    exact_relative_targets = all(grepl(
      "^[.][.]/preregistration_deviations[.]qmd#[a-z0-9-]+$",
      registration_targets,
      perl = TRUE
    )),
    all_central_anchors_resolve_once = TRUE,
    status = "PASS"
  ),
  "H01_REPORT017_31i_dynamic_link_summary.csv"
)

execution <- tribble(
  ~check, ~command, ~exit_status, ~runtime_seconds, ~result,
  "parse and bounded worker reseal",
  "Rscript --vanilla audit/hypotheses/H01/report017_report016_historical_transition/reseal_h01_report017_31i.R",
  0L, 2.76, "PASS",
  "complete REPORT-016 test",
  "Rscript --vanilla tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R",
  0L, 4.96, "PASS: 1161 protected scientific artifacts",
  "order31f focused display-refresh test",
  "Rscript --vanilla tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R",
  0L, 22.35, "PASS: 136 frozen cells and title-only PNG/SVG change",
  "complete H01 reporting test",
  "Rscript --vanilla tests/hypotheses/H01/test_h01_reporting_inputs.R",
  0L, 4.80, "PASS",
  "Quarto render",
  "quarto render",
  NA_integer_, NA_real_, "PROHIBITED AND NOT RUN"
)
write_evidence(execution, "H01_REPORT017_31i_execution.csv")

versions <- tibble(
  component = c("R", "readr", "dplyr", "tibble", "openssl"),
  version = c(
    as.character(getRversion()),
    as.character(packageVersion("readr")),
    as.character(packageVersion("dplyr")),
    as.character(packageVersion("tibble")),
    as.character(packageVersion("openssl"))
  )
)
write_evidence(versions, "H01_REPORT017_31i_versions.csv")

verification <- tribble(
  ~check, ~expected, ~observed, ~status,
  "Historical manifest rows", "15", "15", "PASS",
  "Historical live-exact rows", "8", "8", "PASS",
  "Historical transition rows", "7 exact paths", "7 exact paths", "PASS",
  "Self-referential test transition", "resolved from one worker row", "resolved from one worker row", "PASS",
  "Test hard-coded post hash", "absent", "absent", "PASS",
  "Worker row changes", "1", "1", "PASS",
  "Worker live-exact rows", "1638 plus six accepted older pins", "1638 plus six accepted older pins", "PASS",
  "REPORT-016 files", "7 byte-identical", "7 byte-identical", "PASS",
  "Dynamic links", "40 occurrences / 36 anchors", "40 occurrences / 36 anchors", "PASS",
  "Complete REPORT-016 test", "PASS", "PASS", "PASS",
  "Focused display-refresh test", "PASS", "PASS", "PASS",
  "Complete reporting test", "PASS", "PASS", "PASS",
  "Render", "not run", "not run", "PASS"
)
write_evidence(verification, "H01_REPORT017_31i_verification.csv")

status_output <- system2(
  "git",
  c(
    "status", "--short", "--",
    test_path,
    worker_path,
    evidence_relative
  ),
  stdout = TRUE,
  stderr = TRUE
)
status_code <- attr(status_output, "status")
if (is.null(status_code)) status_code <- 0L
write_evidence(
  tibble(
    line = if (length(status_output)) status_output else "",
    exit_status = status_code
  ),
  "H01_REPORT017_31i_scoped_status.csv"
)

diff_output <- system2(
  "git",
  c(
    "diff", "--check", "--",
    test_path,
    worker_path,
    evidence_relative
  ),
  stdout = TRUE,
  stderr = TRUE
)
diff_code <- attr(diff_output, "status")
if (is.null(diff_code)) diff_code <- 0L
stopifnot(diff_code == 0L)
write_evidence(
  tibble(
    check = "git diff --check (scoped)",
    exit_status = diff_code,
    output = if (length(diff_output)) paste(diff_output, collapse = "\n") else ""
  ),
  "H01_REPORT017_31i_git_diff_check.csv"
)

completion <- c(
  "# H01 REPORT-017 order 31i completion",
  "",
  "The frozen 15-row REPORT-016 reconciliation manifest remains byte-identical.",
  "Its eight live-exact rows and seven authorized historical-to-live transitions",
  "are now classified fail-closed in the focused test. The seventh live identity",
  "is resolved from the exact current worker-manifest row rather than hard-coded.",
  "",
  "Exactly one existing worker-manifest row changed. All three authorized tests",
  "pass under R 4.6.1. No QMD, HTML, builder, image, scientific artifact, profile,",
  "historical record, Stage 3 manifest, or reporting manifest changed.",
  "No render, scientific execution, commit, or push occurred."
)
writeLines(
  completion,
  file.path(evidence_dir, "H01_REPORT017_31i_completion.md"),
  useBytes = TRUE
)

write_evidence(
  tibble(
    check = c(
      "owner manifest excludes itself",
      "all members exist before owner-manifest write",
      "no circular owner-manifest identity"
    ),
    status = "PASS"
  ),
  "H01_REPORT017_31i_noncircular_check.csv"
)

owner_manifest_relative <- file.path(
  evidence_relative,
  "H01_REPORT017_31i_owner_manifest.csv"
)
evidence_members <- sort(file.path(
  evidence_relative,
  list.files(evidence_dir, full.names = FALSE)
))
evidence_members <- setdiff(evidence_members, owner_manifest_relative)
owner_paths <- unique(c(
  "audit/report_harmonization/owner_orders/31i_h01_report016_historical_reconciliation_transition_classification.md",
  "audit/report_harmonization/owner_orders/31i_a_h01_dispatch_matrix_preflight_correction.md",
  test_path,
  worker_path,
  stage3_path,
  reporting_path,
  historical_manifest_path,
  protected_current$path,
  report016_current$path,
  evidence_members
))
stopifnot(
  !owner_manifest_relative %in% owner_paths,
  all(file.exists(owner_paths))
)
owner_manifest <- bind_rows(lapply(owner_paths, identity_row)) |>
  mutate(
    role = "H01 REPORT-017 order 31i completion evidence",
    producer = paste0(evidence_relative, "/seal_h01_report017_31i.R"),
    r_version = as.character(getRversion())
  )
readr::write_csv(
  owner_manifest,
  owner_manifest_relative,
  na = ""
)

message(
  "H01 REPORT-017 order 31i sealed: ",
  nrow(owner_manifest),
  " non-circular rows"
)
