# Metadata/checksum-only recovery seal, no research data or scientific calculation.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
central <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_finishing_metadata_recovery_001"
)
stage <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
)
package <- file.path(stage, "completion_v2/continued_final_package_011")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
verify <- function(p) {
  m <- read.csv(p)
  stopifnot(
    !anyDuplicated(m$path),
    !p %in% m$path,
    all(file.info(m$path)$size == m$bytes),
    identical(unname(vapply(m$path, sha, character(1))), m$sha256)
  )
  m
}
stop_path <- file.path(package, "finalizer_type_stop_manifest.csv")
stopifnot(
  sha(stop_path) ==
    "815ce4cce3f2382cfd1c6f14518d8c89066ec2dee6dd76a586901bee7ee78e6d"
)
stopped <- verify(stop_path)
stopifnot(nrow(stopped) == 11L)
parent <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_stage2_finishing_001/dispatch_manifest.csv"
)
protected <- verify(parent)
stopifnot(nrow(protected) == 3846L)
fixtures <- file.path(
  stage,
  "preflight/analysis_finishing_001/supervisor_fixture_evidence/checks.csv"
)
x <- read.csv(fixtures)
stopifnot(nrow(x) == 41L, identical(x$passed, rep("True", 41L)))
replay <- "/private/tmp/ba018-completion-audit.ekpsA4/finalizer_type_replay_001"
checks <- read.csv(file.path(replay, "finalization_checks.csv"))
stopifnot(nrow(checks) == 28L, all(checks$passed))
absent <- file.path(
  package,
  c(
    "01_complete_finishing_metadata.R",
    "finalization_checks.csv",
    "stage2_handoff.md",
    "author_gate.md",
    "session_and_command.txt",
    "final_manifest.csv",
    "final_manifest_verification.csv"
  )
)
stopifnot(!any(file.exists(absent)))
local_paths <- list.files(central, full.names = TRUE, recursive = TRUE)
local_paths <- local_paths[!file.info(local_paths)$isdir]
paths <- sort(unique(c(
  local_paths,
  stopped$path,
  stop_path,
  parent,
  fixtures,
  file.path(
    replay,
    c(
      "finalization_checks.csv",
      "replay_disposition.txt",
      "prospective_finalizer.R",
      "owner_stop_input_pins.csv"
    )
  ),
  "/private/tmp/ba018-completion-audit.ekpsA4/replay_finalizer_metadata.R"
)))
output <- file.path(central, "dispatch_manifest.csv")
stopifnot(!file.exists(output), !output %in% paths)
write.csv(
  data.frame(
    path = paths,
    bytes = file.info(paths)$size,
    sha256 = unname(vapply(paths, sha, character(1)))
  ),
  output,
  row.names = FALSE
)
m <- verify(output)
cat(
  "METADATA_RECOVERY_DISPATCH=PASS rows=",
  nrow(m),
  " SHA=",
  sha(output),
  "\n",
  sep = ""
)
cat("DECISION=", sha(file.path(central, "decision.md")), "\n", sep = "")
