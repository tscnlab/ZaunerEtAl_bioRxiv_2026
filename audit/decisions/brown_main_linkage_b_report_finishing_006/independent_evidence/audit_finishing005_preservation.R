# Exact independently rehashed resolved historical evidence and current inputs.
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L, !dir.exists(args[1]))
out <- args[1]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
brown <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence"
root <- file.path(
  brown,
  "main_linkage_b_amendment/stage3/reporting/finishing_005/preservation_post_qa"
)
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
input <- file.path(root, "protected_verification.csv")
input_sha <- sha(input)
m <- read.csv(input, check.names = FALSE)
stopifnot(all(m$passed), all(file.exists(m$resolved_path)))
paths <- unique(m$resolved_path)
observed <- setNames(vapply(paths, sha, character(1)), paths)
m$independent_sha256 <- unname(observed[m$resolved_path])
m$independent_bytes <- file.info(m$resolved_path)$size
m$independent_pass <- m$independent_sha256 == m$sha256 &
  m$independent_bytes == m$bytes
stopifnot(all(m$independent_pass), sha(input) == input_sha)
write.csv(
  m,
  file.path(out, "resolved_protection_rehash.csv"),
  row.names = FALSE
)
model_rows <- grepl("\\.(rds|RDS)$", m$path)
stopifnot(all(m$path[model_rows] == m$resolved_path[model_rows]))
leaf_input <- file.path(root, "current_leaf_verification.csv")
leaf <- read.csv(leaf_input)
stopifnot(
  nrow(leaf) == 211L,
  all(leaf$passed),
  all(file.exists(leaf$path)),
  identical(unname(vapply(leaf$path, sha, character(1))), leaf$sha256),
  all(file.info(leaf$path)$size == leaf$bytes)
)
write.csv(
  data.frame(
    check = c(
      "all_resolved_historical_bytes",
      "all_RDS_rows_live_not_remapped",
      "211_current_leaves",
      "evidence_stable"
    ),
    passed = TRUE,
    count = c(nrow(m), sum(model_rows), 211L, 1L)
  ),
  file.path(out, "checks.csv"),
  row.names = FALSE
)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "INDEPENDENT_PRESERVATION=PASS rows=",
  nrow(m),
  " unique_files=",
  length(paths),
  " current_leaves=211\n",
  sep = ""
)
