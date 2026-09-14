# Read-only identity and metadata checks, followed by a non-circular dispatch seal.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
)
central <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_stage2_temporal_transport_recovery_001"
)
evidence <- file.path(central, "independent_evidence")
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
hashes <- function(paths) {
  unique_paths <- unique(paths)
  unname(vapply(unique_paths, sha, character(1))[match(paths, unique_paths)])
}
verify <- function(m) {
  stopifnot(
    !anyNA(m[, c("path", "bytes", "sha256")]),
    !anyDuplicated(m$path),
    all(file.exists(m$path)),
    all(unname(file.info(m$path)$size) == m$bytes),
    identical(hashes(m$path), m$sha256)
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
    "TEMPORAL_TRANSPORT_DISPATCH=PASS rows=%d sha=%s\n",
    nrow(m),
    sha(dispatch)
  ))
  quit(status = 0)
}
package <- file.path(stage, "completion_v2/continued_final_package_009")
mp <- file.path(package, "final_manifest.csv")
stopifnot(
  sha(mp) == "ba20de91310338cfe290c3ff85051c82afccb4261394f14e885ae6bd5313847a"
)
om <- read.csv(mp)
stopifnot(nrow(om) == 1312L, !mp %in% om$path)
verify(om)
protected <- read.csv(file.path(package, "protected_identity_verification.csv"))
stopifnot(
  nrow(protected) == 4533L,
  length(unique(protected$path)) == 2287L,
  all(protected$package009_exact),
  identical(hashes(protected$path), protected$expected_sha256),
  all(unname(file.info(protected$path)$size) == protected$expected_bytes)
)
authority <- read.csv(file.path(package, "authority_verification.csv"))
stopifnot(
  nrow(authority) == 3L,
  all(authority$exact),
  identical(hashes(authority$path), authority$expected_sha256)
)
previous <- read.csv(file.path(
  stage,
  "completion_v2/continued_final_package_008/final_manifest.csv"
))
stopifnot(nrow(previous) == 1215L)
verify(previous)
prior_dispatch <- read.csv(file.path(
  author,
  "audit/decisions/brown_main_linkage_b_stage2_calendar_date_recovery_001/dispatch_manifest.csv"
))
stopifnot(nrow(prior_dispatch) == 3507L)
verify(prior_dispatch)
owner_checks <- read.csv(file.path(package, "finalization_checks.csv"))
stopifnot(nrow(owner_checks) == 33L, all(owner_checks$pass))
map <- read.csv(file.path(central, "exact_owner_copy_map.csv"))
stopifnot(
  nrow(map) == 8L,
  !anyDuplicated(map$destination_path),
  !any(file.exists(map$destination_path)),
  identical(hashes(map$source_path), map$sha256),
  all(unname(file.info(map$source_path)$size) == map$bytes)
)
source <- read.csv(map$source_path[[8L]])
stopifnot(
  nrow(source) == 39L,
  !anyDuplicated(source$path),
  !map$destination_path[[8L]] %in% source$path
)
old <- !source$path %in% map$destination_path
verify(source[old, , drop = FALSE])
index <- match(source$path[!old], map$destination_path)
stopifnot(
  !anyNA(index),
  identical(source$sha256[!old], map$sha256[index]),
  all(source$bytes[!old] == map$bytes[index])
)
for (p in map$source_path[1:5]) invisible(parse(p))
reverse <- read.csv(file.path(central, "source_reverse_proofs.csv"))
stopifnot(
  nrow(reverse) == 5L,
  all(reverse$reverse_exact),
  all(reverse$forward_exact),
  identical(hashes(reverse$old_path), reverse$old_sha256),
  identical(map$sha256[1:5], reverse$new_sha256)
)
supervisor <- readChar(
  map$source_path[[6L]],
  file.info(map$source_path[[6L]])$size,
  useBytes = TRUE
)
changes <- jsonlite::read_json(file.path(
  evidence,
  "supervisor_exact_changes.json"
))
stopifnot(length(changes) == 5L)
for (change in rev(changes))
  supervisor <- sub(change[[2L]], change[[1L]], supervisor, fixed = TRUE)
old_sup <- file.path(stage, "code/run_bounded_job_v9.py")
stopifnot(identical(
  supervisor,
  readChar(old_sup, file.info(old_sup)$size, useBytes = TRUE)
))
csv_checks <- c(
  "calendar_completed_audit_output_001/checks.csv",
  "temporal_transport_audit_output_003/audit_checks.csv",
  "temporal_transport_audit_output_003/temporal/inputs_recovery_001/interface_checks.csv",
  "temporal_transport_audit_output_003/tests/temporal_interfaces_recovery_001/synthetic_checks.csv",
  "supervisor_checks.csv"
)
counts <- c(33L, 16L, 44L, 21L, 52L)
for (i in seq_along(csv_checks)) {
  x <- read.csv(file.path(evidence, csv_checks[[i]]))
  stopifnot(
    nrow(x) == counts[[i]],
    !anyNA(as.logical(x$pass)),
    all(as.logical(x$pass))
  )
}
mock <- jsonlite::read_json(file.path(evidence, "supervisor_summary.json"))
stopifnot(
  isTRUE(mock$passed),
  mock$checks == 52L,
  mock$real_R_children == 0L,
  mock$real_signals == 0L
)
jobs <- list.files(
  file.path(stage, "preflight/execution_jobs"),
  pattern = "finish.json$",
  recursive = TRUE,
  full.names = TRUE
)
stopifnot(length(jobs) == 82L)
j <- lapply(jobs, jsonlite::read_json)
elapsed <- sum(vapply(j, function(x) x$elapsed_seconds, numeric(1)))
stopifnot(
  sum(vapply(j, function(x) x$exit_code != 0L, logical(1))) == 8L,
  all(vapply(
    j,
    function(x) isTRUE(x$child_reaped) && !isTRUE(x$timed_out),
    logical(1)
  ))
)
account <- read.csv(file.path(central, "audit_compute_accounting.csv"))
debit <- sum(account$charged_seconds)
stopifnot(
  nrow(account) == 6L,
  !anyDuplicated(account$component),
  !anyDuplicated(account$basis),
  abs(elapsed - 509.55795420805225) < 1e-9,
  abs(debit - 66.58152158500906) < 1e-9,
  abs(elapsed + debit - 576.1394757930614) < 1e-9
)
stopifnot(
  sha(file.path(stage, "temporal/inputs/ANY.rds")) ==
    "27bcefa91c3370065b22e3bfdd2213ab52031d0c1fded38968d6151b73e73614"
)
absent <- file.path(
  stage,
  c(
    "temporal/inputs_recovery_001",
    "tests/temporal_interfaces_recovery_001",
    "temporal/80",
    "temporal/ANY",
    "diagnostics/temporal_ANY",
    "diagnostics/temporal_80",
    "preflight/computation.lock",
    "completion_v2/continued_final_package_010"
  )
)
stopifnot(!any(file.exists(absent)))
if (mode == "verify_inputs") {
  p <- file.path(central, "independent_input_verification.csv")
  stopifnot(!file.exists(p))
  write.csv(
    data.frame(
      check = c(
        "owner1312",
        "owner33_checks",
        "protected4533_unique2287",
        "authority3",
        "prior1215",
        "prior_dispatch3507",
        "eight_absent_exact_copies",
        "source39_non_circular",
        "five_R_parse_and_reverse",
        "supervisor_five_change_reverse",
        "calendar33",
        "temporal21_44_16",
        "supervisor52",
        "82_histories_eight_failures",
        "budget_once",
        "partial_ANY_exact",
        "new_outputs_absent"
      ),
      pass = TRUE
    ),
    p,
    row.names = FALSE
  )
  cat(
    "TEMPORAL_TRANSPORT_INPUTS=PASS checks=17 owner1312 protected2287 source39 R4.6.1\n"
  )
  quit(status = 0)
}
stopifnot(!file.exists(dispatch))
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
stopifnot(!any(grepl("/supervisor_fixtures_", local)))
paths <- sort(unique(c(
  local,
  om$path,
  mp,
  protected$path,
  authority$path,
  source$path[old]
)))
stopifnot(!dispatch %in% paths, all(file.exists(paths)))
m <- data.frame(
  path = paths,
  bytes = unname(file.info(paths)$size),
  sha256 = hashes(paths)
)
write.csv(m, dispatch, row.names = FALSE)
verify(read.csv(dispatch))
cat(sprintf(
  "TEMPORAL_TRANSPORT_SEAL=PASS rows=%d sha=%s\n",
  nrow(m),
  sha(dispatch)
))
