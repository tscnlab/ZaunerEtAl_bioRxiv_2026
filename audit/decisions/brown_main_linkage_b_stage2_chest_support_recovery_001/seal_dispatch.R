# Metadata and file-identity verification only. No scientific object is loaded.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
)
central <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_stage2_chest_support_recovery_001"
)
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(x) unname(digest::digest(x, algo = "sha256", file = TRUE))
hashes <- function(x) unname(vapply(x, sha, character(1)))
verify <- function(x) {
  stopifnot(
    !anyNA(x),
    !anyDuplicated(x$path),
    all(file.exists(x$path)),
    identical(hashes(x$path), x$sha256),
    all(unname(file.info(x$path)$size) == x$bytes)
  )
  invisible(TRUE)
}
mode <- commandArgs(TRUE)
stopifnot(length(mode) == 1L, mode %in% c("seal", "verify"))
manifest_path <- file.path(central, "dispatch_manifest.csv")
if (mode == "verify") {
  m <- read.csv(manifest_path)
  stopifnot(!(manifest_path %in% m$path))
  verify(m)
  cat(sprintf(
    "BA018_CHEST_DISPATCH_VERIFY=PASS rows=%d sha=%s R=%s\n",
    nrow(m),
    sha(manifest_path),
    getRversion()
  ))
  quit(status = 0)
}
stopifnot(!file.exists(manifest_path))
package <- file.path(stage, "completion_v2/continued_final_package_006")
owner_manifest_path <- file.path(package, "final_manifest.csv")
stopifnot(
  sha(owner_manifest_path) ==
    "b70906505f0f7951abadaa8b4d813cae3508ab68e10f49e6bca3942c65ac8d19"
)
om <- read.csv(owner_manifest_path)
stopifnot(nrow(om) == 1033L, !(owner_manifest_path %in% om$path))
verify(om)
p <- read.csv(file.path(package, "protected_identity_verification.csv"))
stopifnot(
  nrow(p) == 4533L,
  length(unique(p$path)) == 2287L,
  all(p$package006_exact),
  identical(hashes(p$path), p$expected_sha256),
  all(unname(file.info(p$path)$size) == p$expected_bytes)
)
a <- read.csv(file.path(package, "authority_verification.csv"))
stopifnot(all(a$exact), identical(hashes(a$path), a$expected_sha256))
map <- read.csv(file.path(central, "exact_owner_copy_map.csv"))
stopifnot(
  nrow(map) == 5L,
  !anyDuplicated(map$source_path),
  !anyDuplicated(map$destination_path),
  !any(file.exists(map$destination_path)),
  identical(hashes(map$source_path), map$sha256),
  all(unname(file.info(map$source_path)$size) == map$bytes),
  !file.exists(file.path(stage, "placement/chest_b_frames_recovery_001")),
  !file.exists(file.path(stage, "completion_v2/continued_final_package_007")),
  !file.exists(file.path(stage, "preflight/computation.lock"))
)
source_m <- read.csv(map$source_path[[5L]])
stopifnot(
  nrow(source_m) == 29L,
  !anyDuplicated(source_m$path),
  !(map$destination_path[[5L]] %in% source_m$path)
)
old <- !(source_m$path %in% map$destination_path)
verify(source_m[old, , drop = FALSE])
new_idx <- match(source_m$path[!old], map$destination_path)
stopifnot(
  !anyNA(new_idx),
  identical(source_m$sha256[!old], map$sha256[new_idx]),
  identical(source_m$bytes[!old], map$bytes[new_idx])
)
copies <- read.csv(file.path(
  central,
  "independent_evidence_copy_inventory.csv"
))
stopifnot(
  nrow(copies) == 69L,
  identical(hashes(copies$destination), copies$sha256),
  all(unname(file.info(copies$destination)$size) == copies$bytes)
)
proc <- jsonlite::read_json(file.path(central, "process_preflight.json"))
stopifnot(
  isTRUE(proc$no_competing_brown_process),
  identical(proc$matching_count, 0L)
)
checks <- data.frame(
  check = c(
    "owner1033",
    "protected4533_unique2287",
    "authorities",
    "five_copy_sources",
    "five_destinations_absent",
    "output_and_package007_absent",
    "lock_absent",
    "source29_noncircular",
    "independent_copies69",
    "no_competing_brown_process"
  ),
  pass = TRUE
)
write.csv(checks, file.path(central, "dispatch_checks.csv"), row.names = FALSE)
local <- list.files(
  central,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
local <- local[!file.info(local)$isdir]
paths <- sort(unique(c(local, om$path, owner_manifest_path, p$path, a$path)))
stopifnot(!(manifest_path %in% paths), all(file.exists(paths)))
m <- data.frame(
  path = paths,
  bytes = unname(file.info(paths)$size),
  sha256 = hashes(paths)
)
write.csv(m, manifest_path, row.names = FALSE)
verify(read.csv(manifest_path))
cat(sprintf(
  "BA018_CHEST_DISPATCH_SEAL=PASS rows=%d sha=%s owner=1033 protected=2287 checks=10 R=%s\n",
  nrow(m),
  sha(manifest_path),
  getRversion()
))
