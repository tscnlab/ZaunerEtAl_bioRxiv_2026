# Infrastructure identities, archived checks and parse only. No scientific object is loaded.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
)
central <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_stage2_calendar_date_recovery_001"
)
evidence <- file.path(central, "independent_evidence")
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(x) unname(digest::digest(x, algo = "sha256", file = TRUE))
hashes <- function(x) {
  unique_paths <- unique(x)
  unname(vapply(unique_paths, sha, character(1))[match(x, unique_paths)])
}
verify <- function(m) {
  stopifnot(
    !anyNA(m),
    !anyDuplicated(m$path),
    all(file.exists(m$path)),
    identical(hashes(m$path), m$sha256),
    all(unname(file.info(m$path)$size) == m$bytes)
  )
}
mode <- commandArgs(TRUE)
stopifnot(
  length(mode) == 1L,
  mode %in% c("verify_inputs", "seal", "verify_dispatch")
)
dispatch <- file.path(central, "dispatch_manifest.csv")
if (mode == "verify_dispatch") {
  m <- read.csv(dispatch)
  stopifnot(!dispatch %in% m$path)
  verify(m)
  cat(sprintf(
    "CALENDAR_DATE_DISPATCH=PASS rows=%d sha=%s\n",
    nrow(m),
    sha(dispatch)
  ))
  quit(status = 0)
}
package <- file.path(stage, "completion_v2/continued_final_package_008")
mp <- file.path(package, "final_manifest.csv")
stopifnot(
  sha(mp) == "dfae407c449323549930428f73f93792c7c4d2dd895038234fecb2807c5aeab3"
)
om <- read.csv(mp)
stopifnot(nrow(om) == 1215L, !mp %in% om$path)
verify(om)
p <- read.csv(file.path(package, "protected_identity_verification.csv"))
stopifnot(
  nrow(p) == 4533L,
  length(unique(p$path)) == 2287L,
  all(p$package008_exact),
  identical(hashes(p$path), p$expected_sha256),
  all(unname(file.info(p$path)$size) == p$expected_bytes)
)
authority <- read.csv(file.path(package, "authority_verification.csv"))
stopifnot(
  nrow(authority) == 3L,
  all(authority$exact),
  identical(hashes(authority$path), authority$expected_sha256)
)
owner_checks <- read.csv(file.path(package, "finalization_checks.csv"))
stopifnot(nrow(owner_checks) == 27L, all(owner_checks$pass))
map <- read.csv(file.path(central, "exact_owner_copy_map.csv"))
stopifnot(
  nrow(map) == 4L,
  !anyDuplicated(map$destination_path),
  !any(file.exists(map$destination_path)),
  identical(hashes(map$source_path), map$sha256),
  all(unname(file.info(map$source_path)$size) == map$bytes)
)
source <- read.csv(map$source_path[[4L]])
stopifnot(
  nrow(source) == 26L,
  !anyDuplicated(source$path),
  !map$destination_path[[4L]] %in% source$path
)
old <- !source$path %in% map$destination_path
verify(source[old, , drop = FALSE])
index <- match(source$path[!old], map$destination_path)
stopifnot(
  !anyNA(index),
  identical(source$sha256[!old], map$sha256[index]),
  all(source$bytes[!old] == map$bytes[index])
)
invisible(parse(map$source_path[[1L]]))
old_sup <- file.path(stage, "code/run_bounded_job_v8.py")
stopifnot(
  sha(file.path(evidence, "supervisor_v8_reconstructed.py")) == sha(old_sup)
)
new_sup <- readChar(
  map$source_path[[2L]],
  file.info(map$source_path[[2L]])$size,
  useBytes = TRUE
)
original <- readChar(old_sup, file.info(old_sup)$size, useBytes = TRUE)
changes <- jsonlite::read_json(file.path(
  evidence,
  "supervisor_exact_changes.json"
))
stopifnot(length(changes) == 6L)
reversed <- new_sup
for (change in rev(changes))
  reversed <- sub(change[[2L]], change[[1L]], reversed, fixed = TRUE)
stopifnot(identical(reversed, original))
check_sources <- c(
  "calendar_audit_output_001/checks.csv",
  "completed_chest_audit_output_001/checks.csv",
  "completed_diagnostic_audit_output_001/checks.csv",
  "calendar_validator_replay_output_001/checks.csv",
  "calendar_validator_replay_output_001/negative_fixtures.csv",
  "supervisor_checks.csv"
)
expected_counts <- c(64L, 30L, 511L, 14L, 7L, 44L)
for (i in seq_along(check_sources)) {
  z <- read.csv(file.path(evidence, check_sources[[i]]))
  parsed_pass <- as.logical(z$pass)
  stopifnot(
    nrow(z) == expected_counts[[i]],
    !anyNA(parsed_pass),
    all(parsed_pass)
  )
}
jobs <- list.files(
  file.path(stage, "preflight/execution_jobs"),
  pattern = "finish.json$",
  recursive = TRUE,
  full.names = TRUE
)
stopifnot(length(jobs) == 77L)
j <- lapply(jobs, jsonlite::read_json)
elapsed <- sum(vapply(j, function(x) x$elapsed_seconds, numeric(1)))
stopifnot(
  sum(vapply(j, function(x) x$exit_code != 0L, logical(1))) == 7L,
  all(vapply(
    j,
    function(x) isTRUE(x$child_reaped) && !isTRUE(x$timed_out),
    logical(1)
  ))
)
account <- read.csv(file.path(central, "audit_compute_accounting.csv"))
debit <- sum(account$charged_seconds)
stopifnot(
  !anyDuplicated(account$component),
  !anyDuplicated(account$basis),
  abs(elapsed - 492.651775416045) < 1e-9,
  abs(debit - 59.03137896001269) < 1e-9,
  abs(elapsed + debit - 551.6831543760577) < 1e-9
)
absent <- file.path(
  stage,
  c(
    "calendar/saved_frame_validation_001",
    "models/BA-LB-CALENDAR-CHUNKS.rds",
    "temporal",
    "preflight/computation.lock",
    "preflight/execution_jobs/VERIFY-SENSITIVITY-CALENDAR-DATE-RECOVERY-001",
    "completion_v2/continued_final_package_009"
  )
)
stopifnot(!any(file.exists(absent)))
if (mode == "verify_inputs") {
  path <- file.path(central, "independent_input_verification.csv")
  stopifnot(!file.exists(path))
  write.csv(
    data.frame(
      check = c(
        "owner1215",
        "owner27_checks",
        "protected4533_unique2287",
        "authorities3",
        "four_absent_exact_copies",
        "source26_noncircular",
        "validator_parse",
        "supervisor_six_change_reverse",
        "calendar64_chest30_diagnostic511",
        "validator14_fixtures7",
        "supervisor44",
        "77_histories_and_budget_once",
        "outputs_absent"
      ),
      pass = TRUE
    ),
    path,
    row.names = FALSE
  )
  cat(
    "CALENDAR_DATE_INPUTS=PASS checks=13 owner1215 protected2287 source26 R4.6.1\n"
  )
  quit(status = 0)
}
stopifnot(!file.exists(dispatch))
mock <- jsonlite::read_json(file.path(evidence, "supervisor_summary.json"))
stopifnot(
  isTRUE(mock$pass),
  mock$checks == 44L,
  mock$real_R_children == 0L,
  mock$real_signals == 0L
)
proc <- jsonlite::read_json(file.path(central, "process_preflight.json"))
stopifnot(isTRUE(proc$no_competing_brown_process), proc$matching_count == 0L)
local <- list.files(
  central,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
local <- local[!file.info(local)$isdir]
paths <- sort(unique(c(local, om$path, mp, p$path, authority$path)))
stopifnot(!dispatch %in% paths, all(file.exists(paths)))
m <- data.frame(
  path = paths,
  bytes = unname(file.info(paths)$size),
  sha256 = hashes(paths)
)
write.csv(m, dispatch, row.names = FALSE)
verify(read.csv(dispatch))
cat(sprintf("CALENDAR_DATE_SEAL=PASS rows=%d sha=%s\n", nrow(m), sha(dispatch)))
