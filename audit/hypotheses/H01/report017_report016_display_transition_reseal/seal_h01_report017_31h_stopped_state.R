# Seal the fail-closed REPORT-017 order 31h stopped state.

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
  "audit/hypotheses/H01/report017_report016_display_transition_reseal"
evidence_dir <- file.path(root, evidence_relative)
test_path <-
  "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R"
stage3_path <- "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
worker_path <- "artifacts/12_manifests/H01_worker_artifacts.csv"
reporting_path <- "artifacts/12_manifests/H01_reporting_artifacts.csv"
core_path <- paste0(
  "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
  "H01_model_support_fdr_refresh_core_manifest.csv"
)
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
    artifact_sha256(test_path),
    "b0c41cef4a0f373b5ae4da8bcac987493f4d3d46618fd217c964945f5ed8b620"
  ),
  identical(as.numeric(file.info(test_path)$size), 10146),
  identical(
    artifact_sha256(stage3_path),
    "16e752b57eafa43b9cc09d70a698ba194cb3fe83dc62bf1bcc3e08c67f85eb6e"
  ),
  identical(as.numeric(file.info(stage3_path)$size), 26497),
  identical(
    artifact_sha256(worker_path),
    "9a369002e9ebfdc9d99ba08c1bb86b2588d6308b7e844b36fea6336f95e47328"
  ),
  identical(as.numeric(file.info(worker_path)$size), 393672),
  identical(
    artifact_sha256(reporting_path),
    "d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079"
  ),
  identical(
    artifact_sha256(core_path),
    "0207fd8bf4b7a43f185886671ff897a62048d96925186ea9a8756bda1d5b9e12"
  )
)

test_text <- paste(readLines(test_path, warn = FALSE), collapse = "\n")
test_start <- regexpr("\ntransition_contract <- tibble::tibble\\(", test_text)
test_end <- regexpr("\n\nfor \\(index in seq_len\\(nrow\\(manifest\\)\\)\\) \\{", test_text)
stopifnot(test_start[[1]] > 0L, test_end[[1]] > test_start[[1]])
old_gate <- paste0(
  "\nstopifnot(\n",
  "  nrow(protected_current) > 0L,\n",
  "  all(protected_current$sha256 == protected_current$current_sha256),\n",
  "  all(protected_current$bytes == protected_current$current_bytes)\n",
  ")"
)
test_reversed <- paste0(
  substr(test_text, 1L, test_start[[1]] - 1L),
  old_gate,
  substr(test_text, test_end[[1]], nchar(test_text))
)
test_reverse_path <- tempfile(fileext = ".R")
writeBin(charToRaw(paste0(test_reversed, "\n")), test_reverse_path)
test_reverse <- tibble(
  artifact = test_path,
  reconstructed_sha256 = artifact_sha256(test_reverse_path),
  reconstructed_bytes = as.numeric(file.info(test_reverse_path)$size),
  expected_sha256 =
    "bbb994c0c339b39798307dcc8d4f98512518db55856e805ed53684594f6effea",
  expected_bytes = 7861
) |>
  mutate(
    status = if_else(
      .data$reconstructed_sha256 == .data$expected_sha256 &
        .data$reconstructed_bytes == .data$expected_bytes,
      "PASS",
      "FAIL"
    )
  )
stopifnot(identical(test_reverse$status, "PASS"))
unlink(test_reverse_path)
write_evidence(test_reverse, "H01_REPORT017_31h_final_test_reverse.csv")

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
registration_prefix <- "../preregistration_deviations.qmd#"
registration_anchors <- substring(
  registration_targets,
  nchar(registration_prefix) + 1L
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
link_contract <- tibble(
  target = registration_targets,
  anchor = registration_anchors,
  exact_relative_target = grepl(
    "^[.][.]/preregistration_deviations[.]qmd#[a-z0-9-]+$",
    registration_targets,
    perl = TRUE
  ),
  lower_case = registration_anchors == tolower(registration_anchors),
  central_anchor_count = vapply(
    registration_anchors,
    function(anchor) sum(central_anchors == anchor),
    integer(1)
  )
)
stopifnot(
  nrow(link_contract) == 40L,
  length(unique(link_contract$anchor)) == 36L,
  all(link_contract$exact_relative_target),
  all(link_contract$lower_case),
  all(link_contract$central_anchor_count == 1L)
)
write_evidence(link_contract, "H01_REPORT017_31h_dynamic_link_contract.csv")

protected_path <- paste0(
  "audit/hypotheses/H01/report016/",
  "H01_REPORT016_protected_scientific_artifacts.csv"
)
protected <- readr::read_csv(protected_path, show_col_types = FALSE)
protected_live <- protected |>
  mutate(
    current_sha256 = unname(vapply(.data$path, artifact_sha256, character(1))),
    current_bytes = as.numeric(file.info(.data$path)$size),
    status = if_else(
      .data$sha256 == .data$current_sha256 &
        .data$bytes == .data$current_bytes,
      "HISTORICAL_MATCH",
      "APPROVED_DISPLAY_TRANSITION"
    )
  )
transition_paths <- c(
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png",
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg"
)
stopifnot(
  identical(
    sort(protected_live$path[protected_live$status == "APPROVED_DISPLAY_TRANSITION"]),
    sort(transition_paths)
  ),
  sum(protected_live$status == "HISTORICAL_MATCH") == nrow(protected_live) - 2L
)
write_evidence(protected_live, "H01_REPORT017_31h_transition_classification.csv")

report016_pre <- readr::read_csv(
  file.path(evidence_dir, "H01_REPORT017_31h_report016_inventory_pre.csv"),
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
  "H01_REPORT017_31h_report016_inventory_final.csv"
)

stage3_audit <- audit_manifest(stage3_path)
stopifnot(nrow(stage3_audit) == 108L, all(stage3_audit$status == "PASS"))
write_evidence(stage3_audit, "H01_REPORT017_31h_stage3_all_row_audit.csv")

worker_audit <- audit_manifest(worker_path)
expected_worker_historical <- c(
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "_quarto-nathealth.yml",
  "artifacts/12_manifests/H01_reporting_artifacts.csv",
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
write_evidence(worker_audit, "H01_REPORT017_31h_worker_all_row_audit.csv")

historical_audit <- audit_manifest(historical_manifest_path)
expected_historical_mismatches <- c(
  stage3_path,
  reporting_path,
  "notebooks/hypotheses/H01.qmd",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
  test_path
)
stopifnot(
  identical(
    sort(historical_audit$path[historical_audit$status == "MISMATCH"]),
    sort(expected_historical_mismatches)
  ),
  sum(historical_audit$status == "MISMATCH") == 7L
)
write_evidence(
  historical_audit,
  "H01_REPORT017_31h_historical_manifest_stop.csv"
)

stage3_ledger <- readr::read_csv(
  file.path(evidence_dir, "H01_REPORT017_31h_stage3_manifest_ledger.csv"),
  show_col_types = FALSE
)
worker_ledger <- readr::read_csv(
  file.path(evidence_dir, "H01_REPORT017_31h_worker_manifest_ledger.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(stage3_ledger) == 16L,
  sum(stage3_ledger$action == "update_identity") == 3L,
  sum(stage3_ledger$action == "append_core_member") == 13L,
  nrow(worker_ledger) == 18L,
  sum(worker_ledger$action == "update_identity") == 5L,
  sum(worker_ledger$action == "append_core_member") == 13L
)

stage3 <- readr::read_csv(stage3_path, show_col_types = FALSE)
stage3_reversed <- stage3[seq_len(95L), ]
for (index in which(stage3_ledger$action == "update_identity")) {
  path <- stage3_ledger$path[[index]]
  target <- match(path, stage3_reversed$path)
  stage3_reversed$sha256[[target]] <- stage3_ledger$before_sha256[[index]]
  stage3_reversed$bytes[[target]] <- stage3_ledger$before_bytes[[index]]
}
stage3_reverse_path <- tempfile(fileext = ".csv")
readr::write_csv(stage3_reversed, stage3_reverse_path, na = "")

worker <- readr::read_csv(worker_path, show_col_types = FALSE)
worker_reversed <- worker[seq_len(1631L), ]
for (index in which(worker_ledger$action == "update_identity")) {
  path <- worker_ledger$path[[index]]
  target <- match(path, worker_reversed$path)
  worker_reversed$sha256[[target]] <- worker_ledger$before_sha256[[index]]
  worker_reversed$bytes[[target]] <- worker_ledger$before_bytes[[index]]
}
worker_reverse_path <- tempfile(fileext = ".csv")
readr::write_csv(worker_reversed, worker_reverse_path, na = "")
manifest_reverse <- tibble(
  artifact = c(stage3_path, worker_path),
  reconstructed_sha256 = c(
    artifact_sha256(stage3_reverse_path),
    artifact_sha256(worker_reverse_path)
  ),
  reconstructed_bytes = c(
    as.numeric(file.info(stage3_reverse_path)$size),
    as.numeric(file.info(worker_reverse_path)$size)
  ),
  expected_sha256 = c(
    "08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f",
    "51288b656723bc7d29027b3bd5877fa7f18837135d6f7fe1d6c0b96bbe312006"
  ),
  expected_bytes = c(22735, 390741)
) |>
  mutate(
    status = if_else(
      .data$reconstructed_sha256 == .data$expected_sha256 &
        .data$reconstructed_bytes == .data$expected_bytes,
      "PASS",
      "FAIL"
    )
  )
stopifnot(all(manifest_reverse$status == "PASS"))
unlink(c(stage3_reverse_path, worker_reverse_path))
write_evidence(manifest_reverse, "H01_REPORT017_31h_final_manifest_reverse.csv")

execution <- tribble(
  ~check, ~command, ~exit_status, ~runtime_seconds, ~result,
  "parse and bounded reseal",
  "Rscript --vanilla audit/hypotheses/H01/report017_report016_display_transition_reseal/reseal_h01_report017_31h.R",
  0L, 3.34, "PASS",
  "REPORT-016 first run",
  "Rscript --vanilla tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R",
  1L, 4.13, "STOP: named SHA vector rejected by exact identical check",
  "parse and direct test-identity correction",
  "Rscript --vanilla audit/hypotheses/H01/report017_report016_display_transition_reseal/reseal_h01_report017_31h_test_correction.R",
  0L, 2.40, "PASS",
  "REPORT-016 complete rerun",
  "Rscript --vanilla tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R",
  1L, 5.23, "FAIL-CLOSED: unchanged historical reconciliation-manifest gate",
  "order31f focused display-refresh test",
  "Rscript --vanilla tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R",
  NA_integer_, NA_real_, "NOT RUN AFTER FAIL-CLOSED STOP",
  "complete H01 reporting test",
  "Rscript --vanilla tests/hypotheses/H01/test_h01_reporting_inputs.R",
  NA_integer_, NA_real_, "NOT RUN AFTER FAIL-CLOSED STOP",
  "Quarto render",
  "quarto render",
  NA_integer_, NA_real_, "PROHIBITED AND NOT RUN"
)
write_evidence(execution, "H01_REPORT017_31h_execution.csv")

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
write_evidence(versions, "H01_REPORT017_31h_versions.csv")

protected_identities <- bind_rows(lapply(c(
  "notebooks/hypotheses/H01.qmd",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png",
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg",
  "_build/nathealth/notebooks/hypotheses/H01.html",
  reporting_path,
  core_path,
  "audit/hypotheses/H01/report016/H01_REPORT016_protected_scientific_artifacts.csv"
), identity_row))
stopifnot(
  identical(
    protected_identities$sha256,
    c(
      "31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6",
      "962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8",
      "35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7",
      "2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b",
      "602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966",
      "6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa",
      "d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079",
      "0207fd8bf4b7a43f185886671ff897a62048d96925186ea9a8756bda1d5b9e12",
      "94130a6de2e9e127b42267aed5e6dae52e2acc961fa3fb62666ffbf61b3789c7"
    )
  )
)
write_evidence(protected_identities, "H01_REPORT017_31h_protected_identities.csv")

verification <- tribble(
  ~check, ~expected, ~observed, ~status,
  "Stage 3 manifest rows", "108 exact", "108 exact", "PASS",
  "Stage 3 preserved pre-existing rows", "92", "92", "PASS",
  "Stage 3 authorized identity updates", "3", "3", "PASS",
  "Stage 3 allowlisted appends", "13", "13", "PASS",
  "Worker manifest rows", "1644", "1644", "PASS",
  "Worker preserved pre-existing rows outside five updates", "1626", "1626", "PASS",
  "Worker authorized identity updates", "5 plus one bounded correction to the same test row", "5 plus one bounded correction to the same test row", "PASS",
  "Worker allowlisted appends", "13", "13", "PASS",
  "Worker live-exact rows", "1638 with six frozen unrelated historical identities", "1638 with six frozen unrelated historical identities", "PASS_WITH_HISTORICAL_ROWS",
  "REPORT-016 protected files", as.character(nrow(report016_pre)), as.character(nrow(report016_current)), "PASS",
  "Approved protected transitions", "2 exact image paths", "2 exact image paths", "PASS",
  "Dynamic links", "40 occurrences / 36 anchors", "40 occurrences / 36 anchors", "PASS",
  "Historical reconciliation manifest", "unchanged gate", "7 intentionally historical identities differ from live files", "FAIL_CLOSED_STOP",
  "Reporting manifest identity", "d0ed8e0c...", substr(artifact_sha256(reporting_path), 1L, 16L), "PASS",
  "Render", "not run", "not run", "PASS"
)
write_evidence(verification, "H01_REPORT017_31h_verification.csv")

status_output <- system2(
  "git",
  c(
    "status", "--short", "--",
    test_path,
    stage3_path,
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
  "H01_REPORT017_31h_scoped_status.csv"
)

diff_output <- system2(
  "git",
  c(
    "diff", "--check", "--",
    test_path,
    stage3_path,
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
  "H01_REPORT017_31h_git_diff_check.csv"
)

stop_record <- c(
  "# H01 REPORT-017 order 31h fail-closed stop",
  "",
  "The authorized two-image transition classification passed after a bounded",
  "implementation correction that removed a names attribute only at the exact",
  "comparison boundary. The Stage 3 and worker manifests were resealed only for",
  "the authorized direct rows and 13 closed-allowlist additions.",
  "",
  "The complete REPORT-016 test then stopped at the unchanged historical",
  "reconciliation-manifest loop. That manifest contains seven earlier reporting",
  "identities that no longer equal the accepted live files. Order 31h expressly",
  "forbids weakening that separate gate, so the focused display-refresh and full",
  "reporting tests were not run after the stop.",
  "",
  "No QMD, builder, image, HTML, source CSV, scientific output, profile, package,",
  "lockfile, ledger, or manuscript file was edited. No Quarto render or",
  "scientific execution ran. Independent harmonizer disposition is required."
)
writeLines(
  stop_record,
  file.path(evidence_dir, "H01_REPORT017_31h_stopped_state.md"),
  useBytes = TRUE
)

noncircular <- tibble(
  check = c(
    "owner manifest excludes itself",
    "all owner-manifest members existed before owner manifest write",
    "owner manifest contains no circular identity"
  ),
  status = "PASS"
)
write_evidence(noncircular, "H01_REPORT017_31h_noncircular_check.csv")

owner_manifest_relative <- file.path(
  evidence_relative,
  "H01_REPORT017_31h_stopped_state_owner_manifest.csv"
)
evidence_members <- list.files(
  evidence_dir,
  recursive = FALSE,
  full.names = FALSE
)
evidence_members <- sort(file.path(evidence_relative, evidence_members))
evidence_members <- setdiff(evidence_members, owner_manifest_relative)
owner_paths <- unique(c(
  paste0(
    "audit/report_harmonization/owner_orders/",
    "31h_h01_report016_display_transition_manifest_reseal.md"
  ),
  test_path,
  stage3_path,
  worker_path,
  reporting_path,
  protected_identities$path,
  report016_current$path,
  evidence_members
))
stopifnot(
  !owner_manifest_relative %in% owner_paths,
  all(file.exists(owner_paths))
)
owner_manifest <- bind_rows(lapply(owner_paths, identity_row)) |>
  mutate(
    role = "H01 REPORT-017 order 31h stopped-state evidence",
    producer = paste0(
      evidence_relative,
      "/seal_h01_report017_31h_stopped_state.R"
    ),
    r_version = as.character(getRversion())
  )
readr::write_csv(
  owner_manifest,
  file.path(root, owner_manifest_relative),
  na = ""
)

message(
  "H01 REPORT-017 order 31h stopped state sealed: ",
  nrow(owner_manifest),
  " non-circular rows"
)
