# File identities and source AST only. No scientific data/model is loaded.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
)
central <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_stage2_chest_prefit_recovery_001"
)
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(x) unname(digest::digest(x, algo = "sha256", file = TRUE))
hashes <- function(x) unname(vapply(x, sha, character(1)))
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
  stopifnot(!(dispatch %in% m$path))
  verify(m)
  cat(sprintf(
    "CHEST_PREFIT_DISPATCH=PASS rows=%d sha=%s\n",
    nrow(m),
    sha(dispatch)
  ))
  quit(status = 0)
}
package <- file.path(stage, "completion_v2/continued_final_package_007")
mp <- file.path(package, "final_manifest.csv")
stopifnot(
  sha(mp) == "946038dbd06d694d27873f47bac8d742dd0cf27be55a2e2d8090ebd522b30865"
)
om <- read.csv(mp)
stopifnot(nrow(om) == 1080L, !(mp %in% om$path))
verify(om)
p <- read.csv(file.path(package, "protected_identity_verification.csv"))
stopifnot(
  nrow(p) == 4533L,
  length(unique(p$path)) == 2287L,
  all(p$package007_exact),
  identical(hashes(p$path), p$expected_sha256),
  all(unname(file.info(p$path)$size) == p$expected_bytes)
)
authority <- read.csv(file.path(package, "authority_verification.csv"))
stopifnot(
  all(authority$exact),
  identical(hashes(authority$path), authority$expected_sha256)
)
map <- read.csv(file.path(central, "exact_owner_copy_map.csv"))
stopifnot(
  nrow(map) == 4L,
  !anyDuplicated(map$destination_path),
  !any(file.exists(map$destination_path)),
  identical(hashes(map$source_path), map$sha256),
  all(unname(file.info(map$source_path)$size) == map$bytes)
)
sm <- read.csv(map$source_path[[4L]])
stopifnot(
  nrow(sm) == 27L,
  !anyDuplicated(sm$path),
  !(map$destination_path[[4L]] %in% sm$path)
)
old <- !(sm$path %in% map$destination_path)
verify(sm[old, , drop = FALSE])
new_idx <- match(sm$path[!old], map$destination_path)
stopifnot(
  !anyNA(new_idx),
  identical(sm$sha256[!old], map$sha256[new_idx]),
  all(sm$bytes[!old] == map$bytes[new_idx])
)
ev <- file.path(central, "independent_evidence")
stopifnot(
  sha(file.path(ev, "driver_reconstructed.R")) ==
    sha(file.path(stage, "code/19_fit_chest_b.R")),
  sha(file.path(ev, "supervisor_v7_reconstructed.py")) ==
    sha(file.path(stage, "code/run_bounded_job_v7.py"))
)
old_source <- readChar(
  file.path(stage, "code/19_fit_chest_b.R"),
  file.info(file.path(stage, "code/19_fit_chest_b.R"))$size,
  useBytes = TRUE
)
new_source <- readChar(
  map$source_path[[1L]],
  file.info(map$source_path[[1L]])$size,
  useBytes = TRUE
)
changes <- jsonlite::read_json(file.path(ev, "driver_exact_changes.json"))
stopifnot(length(changes) == 4L)
reverse <- new_source
for (z in rev(changes)) reverse <- sub(z[[2L]], z[[1L]], reverse, fixed = TRUE)
stopifnot(identical(reverse, old_source))
parse(text = new_source, keep.source = FALSE)
source_checks <- read.csv(file.path(ev, "full_prefit/checks.csv"))
scope <- read.csv(file.path(ev, "full_prefit/scope.csv"))
stopifnot(
  nrow(source_checks) == 40L,
  all(source_checks$pass),
  all(scope$count == 0L)
)
absent <- file.path(
  stage,
  c(
    "models/BA-LB-CHEST-ANY.rds",
    "models/BA-LB-CHEST-ANY_input.rds",
    "models/BA-LB-CHEST-ANY_manifest.csv",
    "placement/chest_fit_prefit_ranks.csv",
    "preflight/computation.lock",
    "preflight/execution_jobs/CHEST-ANY-PREFIT-RECOVERY-001",
    "completion_v2/continued_final_package_008"
  )
)
stopifnot(!any(file.exists(absent)))
if (mode == "verify_inputs") {
  out <- file.path(central, "independent_input_verification.csv")
  stopifnot(!file.exists(out))
  checks <- data.frame(
    check = c(
      "owner1080",
      "protected4533_unique2287",
      "authorities",
      "four_absent_destinations",
      "source27_noncircular",
      "driver_four_exact_changes_reverse",
      "supervisor_exact_reverse",
      "full_prefit40",
      "zero_real_science_fixture",
      "new_outputs_absent"
    ),
    pass = TRUE
  )
  write.csv(checks, out, row.names = FALSE)
  cat(
    "CHEST_PREFIT_INPUTS=PASS owner1080 protected2287 source27 checks10 R4.6.1\n"
  )
  quit(status = 0)
}
stopifnot(!file.exists(dispatch))
mock <- jsonlite::read_json(file.path(ev, "supervisor_summary.json"))
stopifnot(
  isTRUE(mock$pass),
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
stopifnot(!(dispatch %in% paths), all(file.exists(paths)))
m <- data.frame(
  path = paths,
  bytes = unname(file.info(paths)$size),
  sha256 = hashes(paths)
)
write.csv(m, dispatch, row.names = FALSE)
verify(read.csv(dispatch))
cat(sprintf("CHEST_PREFIT_SEAL=PASS rows=%d sha=%s\n", nrow(m), sha(dispatch)))
