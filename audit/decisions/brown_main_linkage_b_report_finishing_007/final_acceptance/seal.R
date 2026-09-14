# Seal the final reporting amendment only after independent current-page acceptance.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
scope <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_007"
)
base <- file.path(scope, "final_acceptance")
process <- file.path(scope, "process_disposition")
brown <- file.path(owner, "audit/analyses/brown_adherence")
work <- file.path(
  brown,
  "main_linkage_b_amendment/stage3/reporting/finishing_007"
)
temp <- "/private/tmp/ba018-completion-audit.ekpsA4"
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
target <- file.path(base, "final_manifest.csv")
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
args <- commandArgs(TRUE)
stopifnot(length(args) >= 1L, args[1] %in% c("seal", "verify"))
if (args[1] == "verify") {
  stopifnot(length(args) == 1L)
  m <- verify(target)
  cat(
    "FINISHING007_FINAL_ACCEPTANCE=PASS members=",
    nrow(m),
    " manifest=",
    sha(target),
    "\n",
    sep = ""
  )
  quit(status = 0)
}
stopifnot(
  length(args) == 5L,
  !file.exists(target),
  file.exists(file.path(base, "acceptance.md")),
  file.exists(file.path(base, "independent_visual_review.md"))
)
package <- normalizePath(args[2], mustWork = TRUE)
stopifnot(startsWith(package, paste0(work, "/")), sha(package) == args[3])
m <- verify(package)
stopifnot(
  nrow(m) == as.integer(args[4]),
  !any(startsWith(m$path, paste0(base, "/")))
)
process_manifest <- file.path(process, "manifest.csv")
stopifnot(
  sha(process_manifest) ==
    "db546882320d85b7306e2d88877cd98aa611c8a57e78a97ad2ecf1d4aebb5484"
)
pm <- verify(process_manifest)
executions <- c(
  "results007_main_cells_raw_execution_001",
  "results007_exploratory_cells_raw_execution_001",
  "results007_figures_raw_execution_001",
  "results007_ledger_execution_001",
  "results007_structure_execution_001",
  "results007_final_preservation_execution_001",
  "results007_package_execution_001"
)
archive <- file.path(base, "independent_evidence")
stopifnot(!dir.exists(archive))
dir.create(archive)
copy_tree <- function(name) {
  from <- file.path(temp, name)
  to <- file.path(archive, name)
  stopifnot(dir.exists(from), !dir.exists(to))
  paths <- list.files(
    from,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE
  )
  paths <- paths[!file.info(paths)$isdir]
  for (p in paths) {
    destination <- file.path(to, substring(p, nchar(from) + 2L))
    dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
    stopifnot(
      !file.exists(destination),
      file.copy(p, destination, overwrite = FALSE),
      sha(p) == sha(destination)
    )
  }
}
accounting <- data.frame(
  component = "previous_sealed_accounting",
  basis = file.path(process, "audit_compute_accounting.csv"),
  charged_seconds = sum(
    read.csv(file.path(process, "audit_compute_accounting.csv"))$charged_seconds
  )
)
for (e in executions) {
  f <- jsonlite::read_json(file.path(temp, e, "finish.json"))
  stopifnot(f$exit_code == 0L, !f$timed_out, f$child_reaped)
  copy_tree(e)
  copy_tree(sub("_execution_", "_output_", e, fixed = TRUE))
  accounting <- rbind(
    accounting,
    data.frame(
      component = e,
      basis = file.path(archive, e, "finish.json"),
      charged_seconds = f$elapsed_seconds
    )
  )
}
for (n in c(
  "audit_reader_table_bindings.R",
  "audit_results007_exploratory_tables.R",
  "audit_embedded_report_figures.R",
  "audit_semantic_ledger_exact.R",
  "audit_reader_structure.R",
  "audit_resolved_preservation.R",
  "audit_non_circular_manifest.R"
)) {
  stopifnot(
    file.copy(file.path(temp, n), file.path(archive, n), overwrite = FALSE),
    sha(file.path(temp, n)) == sha(file.path(archive, n))
  )
}
stopifnot(
  sum(accounting$charged_seconds) < 1200,
  !anyDuplicated(accounting$basis)
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
  "5f444f3ea9d7d93da8c4f2337aef215ac01c7e275c7098076dc223695d7d84ac",
  args[5],
  "4009da02e9239835a0b3a74381472034bc5d478f5b7491e73e80ce88548c4272",
  "88abd9927cc8f81690346c95626903031b7735797bfa3b2786d517c3d417f198",
  "92c3e5f4d49878c667cd4fcdaea6ee812ff9e3ea84f916f448aa2ee75a9c2013",
  "e3e189ea1fa1b4038de4b8fdcc3f6a811dcaf6c8a3231bda45e21a2c5e4f65f7"
)
stopifnot(identical(unname(vapply(current, sha, character(1))), expected))
write.csv(
  data.frame(
    path = current,
    bytes = file.info(current)$size,
    sha256 = expected
  ),
  file.path(base, "accepted_reports.csv"),
  row.names = FALSE
)
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
science <- file.path(
  brown,
  "main_linkage_b_amendment/stage2/completion_v2/continued_final_package_011/final_manifest.csv"
)
stopifnot(
  sha(science) ==
    "c1ce90bf88ff3597d6a75419ee331f091d0a867735117e8785973e1f172af696"
)
paths <- unique(c(
  m$path,
  package,
  file.path(dirname(package), "final_manifest_verification.csv"),
  pm$path,
  process_manifest,
  current,
  leaf_path,
  leaf_paths,
  science,
  file.path(scope, c("decision.md", "dispatch_manifest.csv")),
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
  "FINISHING007_FINAL_SEAL=PASS members=",
  nrow(m),
  " manifest=",
  sha(target),
  " acceptance=",
  sha(file.path(base, "acceptance.md")),
  " cumulative_audit_seconds=",
  sum(accounting$charged_seconds),
  "\n",
  sep = ""
)
