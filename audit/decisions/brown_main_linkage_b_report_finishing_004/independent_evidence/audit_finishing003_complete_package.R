# Read-only independent acceptance of the completed internal report.
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L, !dir.exists(args[1]))
out <- args[1]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages(library(data.table))
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
brown <- file.path(owner, "audit/analyses/brown_adherence")
base <- file.path(brown, "main_linkage_b_amendment")
pack <- file.path(base, "stage2/reporting/recovery_003/completed_package")
manifest <- file.path(pack, "final_manifest.csv")
stopifnot(
  sha(manifest) ==
    "6133f1fe75050181d44755b3d1acfceb878442cfb68f8abf445bd763e19a684a"
)
cache <- new.env(parent = emptyenv())
cached_sha <- function(p) {
  if (!exists(p, cache, inherits = FALSE)) assign(p, sha(p), cache)
  get(p, cache, inherits = FALSE)
}
verify <- function(x, actual = "path") {
  p <- x[[actual]]
  stopifnot(all(file.exists(p)), !any(file.info(p)$isdir))
  x[, observed_sha256 := vapply(p, cached_sha, character(1))]
  x[, observed_bytes := file.info(p)$size]
  x[, passed := sha256 == observed_sha256 & bytes == observed_bytes]
  stopifnot(all(x$passed))
  x
}
m <- fread(manifest)
stopifnot(nrow(m) == 484L, !anyDuplicated(m$path), !manifest %in% m$path)
fwrite(verify(copy(m)), file.path(out, "owner_manifest_rehash.csv"))
checks <- fread(file.path(pack, "finalization_checks.csv"))
stopifnot(nrow(checks) == 29L, !anyDuplicated(checks$check), all(checks$passed))
protected <- fread(file.path(
  base,
  "stage3/evidence/report_finishing_003/preservation_post_qa/protected_verification.csv"
))
stopifnot(nrow(protected) == 10005L, all(protected$passed))
old <- fread(file.path(
  base,
  "stage3/evidence/report_finishing_001/canonical_history_map.csv"
))
maps <- rbindlist(list(
  old[, .(
    canonical_path,
    expected_sha256 = preimage_sha256,
    expected_bytes = bytes,
    historical_copy = history_path
  )],
  fread(file.path(
    base,
    "stage3/evidence/report_finishing_002/exact_preimage_map.csv"
  )),
  fread(file.path(
    base,
    "stage3/evidence/report_finishing_003/exact_preimage_map.csv"
  ))
))
stopifnot(!anyDuplicated(maps[, .(canonical_path, expected_sha256)]))
expected_resolved <- vapply(
  seq_len(nrow(protected)),
  function(i) {
    hit <- which(
      maps$canonical_path == protected$path[i] &
        maps$expected_sha256 == protected$sha256[i] &
        maps$expected_bytes == protected$bytes[i]
    )
    stopifnot(length(hit) <= 1L)
    if (length(hit)) maps$historical_copy[hit] else protected$path[i]
  },
  character(1)
)
stopifnot(identical(expected_resolved, protected$resolved_path))
fwrite(
  verify(copy(protected), "resolved_path"),
  file.path(out, "protected_rehash.csv")
)
leaf_path <- file.path(
  base,
  "stage3/evidence/report_finishing_001/reader_input_manifest.csv"
)
stopifnot(
  sha(leaf_path) ==
    "9e6ce54153ded6613c74dd8b026d28c1ea244ad841c136e2d28d92e49a34048d"
)
leaf <- fread(leaf_path)
leaf[, path := file.path(brown, relative_path)]
stopifnot(!anyDuplicated(leaf$path))
fwrite(verify(leaf), file.path(out, "current_leaf_rehash.csv"))
pins <- data.table(
  path = c(
    manifest,
    file.path(
      pack,
      c(
        "handoff.md",
        "finalization_checks.csv",
        "final_manifest_verification.csv"
      )
    ),
    leaf_path
  )
)
pins[, `:=`(
  bytes = file.info(path)$size,
  sha256 = vapply(path, sha, character(1))
)]
fwrite(pins, file.path(out, "acceptance_pins.csv"))
fwrite(
  data.table(
    check = c(
      "owner_manifest_484",
      "finalization_29",
      "protected_10005",
      "exact_historical_resolver",
      "current_leaf_exact"
    ),
    passed = TRUE
  ),
  file.path(out, "checks.csv")
)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "FINISHING003_INDEPENDENT=PASS owner=484/484 finalization=29/29 protected=10005/10005 leaf=",
  nrow(leaf),
  " R=",
  as.character(getRversion()),
  "\n",
  sep = ""
)
