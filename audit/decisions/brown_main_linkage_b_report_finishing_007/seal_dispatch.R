# Non-circular coordination inventory; no scientific calculation or author edit.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
base <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_007"
)
prior <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_technical_completion_2026_09_13"
)
temp <- "/private/tmp/ba018-completion-audit.ekpsA4"
target <- file.path(base, "dispatch_manifest.csv")
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L, args %in% c("seal", "verify"))
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
verify <- function(p) {
  m <- read.csv(p, check.names = FALSE)
  stopifnot(
    !anyDuplicated(m$path),
    !p %in% m$path,
    all(file.exists(m$path)),
    all(file.info(m$path)$size == m$bytes),
    identical(unname(vapply(m$path, sha, character(1))), m$sha256)
  )
  m
}
if (args == "verify") {
  m <- verify(target)
  cat(
    "FINISHING007_DISPATCH=PASS members=",
    nrow(m),
    " sha=",
    sha(target),
    "\n",
    sep = ""
  )
  quit(status = 0)
}
stopifnot(!file.exists(target))
prior_manifest <- file.path(prior, "final_manifest.csv")
stopifnot(
  sha(prior_manifest) ==
    "7c5b7e80cf0557bc8dda86d1d23be4b223a4ec6fcf7bbb5ef8c4bb39c0cc7eb4"
)
old <- verify(prior_manifest)
stopifnot(nrow(old) == 610L)
copy_tree <- function(from, to) {
  stopifnot(dir.exists(from), !dir.exists(to))
  dir.create(to, recursive = TRUE)
  p <- list.files(from, recursive = TRUE, full.names = TRUE, all.files = TRUE)
  p <- p[!file.info(p)$isdir]
  dest <- file.path(to, substring(p, nchar(from) + 2L))
  for (i in seq_along(p)) {
    dir.create(dirname(dest[i]), recursive = TRUE, showWarnings = FALSE)
    stopifnot(
      !file.exists(dest[i]),
      file.copy(p[i], dest[i], overwrite = FALSE),
      sha(p[i]) == sha(dest[i])
    )
  }
}
approved <- file.path(base, "approved_source")
copy_tree(file.path(temp, "finishing007_scope_output_003"), approved)
stopifnot(
  sha(file.path(approved, "baseline_results.qmd")) ==
    "988a9a532e0406da22e254bdc1548c9af5c13134f2abd184cd3127be81d862e7",
  sha(file.path(approved, "prospective_results.qmd")) ==
    "5f444f3ea9d7d93da8c4f2337aef215ac01c7e275c7098076dc223695d7d84ac",
  nrow(read.csv(file.path(approved, "exact_source_matrix.csv"))) == 14L,
  all(read.csv(file.path(approved, "checks.csv"))$passed),
  nrow(read.csv(file.path(approved, "added_inline_contract.csv"))) == 8L,
  nrow(read.csv(file.path(approved, "expected_heading_inventory.csv"))) == 20L
)
evidence <- file.path(base, "independent_evidence")
dir.create(evidence)
executions <- c(
  "finishing007_inputs_execution_001",
  paste0("finishing007_scope_execution_00", 1:3)
)
account <- data.frame(
  component = "prior_sealed_accounting",
  basis = file.path(prior, "audit_compute_accounting.csv"),
  charged_seconds = sum(
    read.csv(file.path(prior, "audit_compute_accounting.csv"))$charged_seconds
  ),
  status = "SEALED"
)
for (n in executions) {
  copy_tree(file.path(temp, n), file.path(evidence, n))
  f <- jsonlite::read_json(file.path(evidence, n, "finish.json"))
  stopifnot(
    f$child_reaped,
    !f$timed_out,
    f$exit_code == if (n == "finishing007_scope_execution_001") 1L else 0L
  )
  copy_tree(
    file.path(temp, sub("_execution_", "_output_", n, fixed = TRUE)),
    file.path(evidence, sub("_execution_", "_output_", n, fixed = TRUE))
  )
  account <- rbind(
    account,
    data.frame(
      component = n,
      basis = file.path(evidence, n, "finish.json"),
      charged_seconds = f$elapsed_seconds,
      status = if (f$exit_code == 0L) "PASS" else
        "PRESERVED_EXACT_MATCH_GUARD_STOP"
    )
  )
}
for (n in c(
  "inspect_finishing007_inputs.R",
  "prepare_finishing007_scope.R",
  "prepare_finishing007_scope_v2.R",
  "prepare_finishing007_scope_v3.R"
)) {
  stopifnot(
    file.copy(file.path(temp, n), file.path(evidence, n), overwrite = FALSE),
    sha(file.path(temp, n)) == sha(file.path(evidence, n))
  )
}
stopifnot(!anyDuplicated(account$basis), sum(account$charged_seconds) < 1200)
write.csv(
  account,
  file.path(base, "audit_compute_accounting.csv"),
  row.names = FALSE
)
write.csv(
  old,
  file.path(base, "accepted_current_protection.csv"),
  row.names = FALSE
)
paths <- unique(c(
  old$path,
  prior_manifest,
  list.files(base, recursive = TRUE, full.names = TRUE, all.files = TRUE)
))
paths <- sort(paths[!file.info(paths)$isdir])
stopifnot(
  !target %in% paths,
  all(file.exists(paths)),
  !any(startsWith(paths, "/private/tmp/"))
)
write.csv(
  data.frame(
    path = paths,
    bytes = file.info(paths)$size,
    sha256 = unname(vapply(paths, sha, character(1)))
  ),
  target,
  row.names = FALSE
)
m <- verify(target)
cat(
  "FINISHING007_SEALED=PASS members=",
  nrow(m),
  " decision=",
  sha(file.path(base, "decision.md")),
  " dispatch=",
  sha(target),
  " matrix=",
  sha(file.path(approved, "exact_source_matrix.csv")),
  " cumulative_audit_seconds=",
  sum(account$charged_seconds),
  "\n",
  sep = ""
)
