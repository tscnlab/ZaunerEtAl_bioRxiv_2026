# Infrastructure-only dispatch sealing after independent results acceptance.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
base <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_006"
)
prior <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_005"
)
temp <- "/private/tmp/ba018-completion-audit.ekpsA4"
brown <- file.path(owner, "audit/analyses/brown_adherence")
args <- commandArgs(TRUE)
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
target <- file.path(base, "dispatch_manifest.csv")
verify <- function(path) {
  m <- read.csv(path, check.names = FALSE)
  stopifnot(
    !anyDuplicated(m$path),
    !path %in% m$path,
    all(file.exists(m$path)),
    all(file.info(m$path)$size == m$bytes),
    identical(unname(vapply(m$path, sha, character(1))), m$sha256)
  )
  m
}
stopifnot(length(args) >= 1L, args[1] %in% c("seal", "verify"))
if (args[1] == "verify") {
  stopifnot(length(args) == 1L)
  m <- verify(target)
  cat(
    "FINISHING006_DISPATCH=PASS members=",
    nrow(m),
    " manifest=",
    sha(target),
    "\n",
    sep = ""
  )
  quit(status = 0)
}
stopifnot(
  length(args) == 4L,
  !file.exists(target),
  file.exists(file.path(base, "results_internal_independent_acceptance.md"))
)
owner_manifest <- normalizePath(args[2], mustWork = TRUE)
stopifnot(
  startsWith(
    owner_manifest,
    file.path(brown, "main_linkage_b_amendment/stage3/reporting/finishing_005/")
  ),
  sha(owner_manifest) == args[3]
)
m <- verify(owner_manifest)
stopifnot(nrow(m) == as.integer(args[4]))
write.csv(
  data.frame(path = owner_manifest, sha256 = args[3], rows = nrow(m)),
  file.path(base, "accepted_owner_package.csv"),
  row.names = FALSE
)
archive <- file.path(base, "independent_evidence")
stopifnot(!dir.exists(archive))
dir.create(archive)
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
executions <- c(
  "mermaid_regression_execution_001",
  "finishing005_transitions_execution_001",
  "internal005_cells_execution_001",
  "results005_raw_images_execution_001",
  paste0(
    "results005_",
    c(
      "headings",
      "cells",
      "images",
      "exploratory",
      "inline",
      "structure",
      "ledger"
    ),
    "_execution_001"
  ),
  "finishing005_package_execution_001",
  "finishing005_preservation_execution_001"
)
accounting <- data.frame(
  component = "previous_sealed_accounting",
  basis = file.path(prior, "audit_compute_accounting.csv"),
  charged_seconds = sum(
    read.csv(file.path(prior, "audit_compute_accounting.csv"))$charged_seconds
  )
)
for (n in executions) {
  copy_tree(file.path(temp, n), file.path(archive, n))
  f <- jsonlite::read_json(file.path(archive, n, "finish.json"))
  stopifnot(!f$timed_out, f$child_reaped, f$exit_code == 0L)
  accounting <- rbind(
    accounting,
    data.frame(
      component = n,
      basis = file.path(archive, n, "finish.json"),
      charged_seconds = f$elapsed_seconds
    )
  )
  o <- sub("_execution_", "_output_", n, fixed = TRUE)
  copy_tree(file.path(temp, o), file.path(archive, o))
}
for (n in c(
  "audit_non_circular_manifest.R",
  "audit_finishing005_preservation.R",
  "audit_finishing005_five_transitions.R",
  "audit_reader_mermaid.R",
  "audit_mermaid_validator_regression.R",
  "audit_reader_structure.R",
  "audit_reader_complete_headings.R",
  "audit_reader_table_bindings.R",
  "audit_embedded_report_figures.R",
  "audit_semantic_ledger_exact.R",
  "audit_reader_inline_context.R"
)) {
  stopifnot(
    file.copy(file.path(temp, n), file.path(archive, n), overwrite = FALSE),
    sha(file.path(temp, n)) == sha(file.path(archive, n))
  )
}
stopifnot(
  !anyDuplicated(accounting$basis),
  sum(accounting$charged_seconds) < 1200
)
write.csv(
  accounting,
  file.path(base, "audit_compute_accounting.csv"),
  row.names = FALSE
)
current <- file.path(
  brown,
  c(
    "13_cross_state_association_results_amendment.qmd",
    "13_cross_state_association_results_amendment.html",
    "14_cross_state_association_preparation_and_provenance.qmd",
    "14_cross_state_association_preparation_and_provenance.html",
    "main_linkage_b_amendment/stage2/implementation_and_reconciliation.qmd",
    "main_linkage_b_amendment/stage2/implementation_and_reconciliation.html"
  )
)
expected <- c(
  "988a9a532e0406da22e254bdc1548c9af5c13134f2abd184cd3127be81d862e7",
  "37d38f0c97a7638fbeba1cd974b6bf5a3a81c9d7be4200d5af9a7ec656695308",
  "4009da02e9239835a0b3a74381472034bc5d478f5b7491e73e80ce88548c4272",
  "54e85fe7873a8b54772341ce95241e5dc93ec7ab14aef99f0b1b72773b0f5954",
  "92c3e5f4d49878c667cd4fcdaea6ee812ff9e3ea84f916f448aa2ee75a9c2013",
  "e3e189ea1fa1b4038de4b8fdcc3f6a811dcaf6c8a3231bda45e21a2c5e4f65f7"
)
stopifnot(identical(unname(vapply(current, sha, character(1))), expected))
leaf_path <- file.path(
  brown,
  "main_linkage_b_amendment/stage3/evidence/report_finishing_001/reader_input_manifest.csv"
)
stopifnot(
  sha(leaf_path) ==
    "79da2fe8bb215fab36b70905552272444bfdce9d5e9bb7d6f264ffb52a3854a0"
)
leaf <- read.csv(leaf_path)
leaf_paths <- file.path(brown, leaf$relative_path)
stopifnot(
  nrow(leaf) == 211L,
  !anyDuplicated(leaf_paths),
  identical(unname(vapply(leaf_paths, sha, character(1))), leaf$sha256),
  all(file.info(leaf_paths)$size == leaf$bytes)
)
paths <- unique(c(
  m$path,
  owner_manifest,
  file.path(dirname(owner_manifest), "final_manifest_verification.csv"),
  current,
  leaf_path,
  leaf_paths,
  file.path(
    prior,
    c("decision.md", "dispatch_manifest.csv", "audit_compute_accounting.csv")
  ),
  list.files(base, recursive = TRUE, full.names = TRUE, all.files = TRUE)
))
paths <- sort(paths[!file.info(paths)$isdir])
stopifnot(!target %in% paths, all(file.exists(paths)))
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
  "FINISHING006_SEAL=PASS members=",
  nrow(m),
  " manifest=",
  sha(target),
  " decision=",
  sha(file.path(base, "decision.md")),
  " acceptance=",
  sha(file.path(base, "results_internal_independent_acceptance.md")),
  " cumulative_audit_seconds=",
  sum(accounting$charged_seconds),
  "\n",
  sep = ""
)
