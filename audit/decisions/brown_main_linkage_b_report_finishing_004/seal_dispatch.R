# Non-analytical, exact dispatch inventory and existing audit-time accounting.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
base <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_004"
)
prior <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_003"
)
temp <- "/private/tmp/ba018-completion-audit.ekpsA4"
brown <- file.path(owner, "audit/analyses/brown_adherence")
pack <- file.path(
  brown,
  "main_linkage_b_amendment/stage2/reporting/recovery_003/completed_package"
)
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
mode <- commandArgs(TRUE)
stopifnot(length(mode) == 1L, mode %in% c("seal", "verify"))
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
if (mode == "verify") {
  m <- verify(target)
  cat(
    "FINISHING004_DISPATCH=PASS members=",
    nrow(m),
    " SHA256=",
    sha(target),
    "\n",
    sep = ""
  )
  quit(status = 0)
}
stopifnot(!file.exists(target))
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
  "heading_regression_execution_001",
  "internal003_headings_execution_001",
  "internal003_cells_execution_001",
  "internal003_images_execution_001",
  "internal003_semantic_structure_execution_001",
  "internal003_ledger_execution_001",
  "finishing003_package_execution_001"
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
  stopifnot(!f$timed_out, f$child_reaped, f$exit_code %in% c(0L, 1L))
  accounting <- rbind(
    accounting,
    data.frame(
      component = n,
      basis = file.path(archive, n, "finish.json"),
      charged_seconds = f$elapsed_seconds
    )
  )
}
for (n in c(
  "heading_regression_output_001",
  "internal003_headings_output_001",
  "internal003_cells_output_001",
  "internal003_images_output_001",
  "internal003_semantic_structure_output_001",
  "internal003_ledger_output_001",
  "finishing003_package_output_001"
))
  copy_tree(file.path(temp, n), file.path(archive, n))
for (n in c(
  "audit_finishing003_complete_package.R",
  "audit_reader_structure.R",
  "audit_reader_complete_headings.R",
  "audit_reader_table_bindings.R",
  "audit_embedded_report_figures.R",
  "audit_semantic_ledger_exact.R",
  "audit_exploratory_reader_tables.R",
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
owner_manifest <- file.path(pack, "final_manifest.csv")
stopifnot(
  sha(owner_manifest) ==
    "6133f1fe75050181d44755b3d1acfceb878442cfb68f8abf445bd763e19a684a"
)
m <- verify(owner_manifest)
stopifnot(nrow(m) == 484L)
leaf_path <- file.path(
  brown,
  "main_linkage_b_amendment/stage3/evidence/report_finishing_001/reader_input_manifest.csv"
)
stopifnot(
  sha(leaf_path) ==
    "9e6ce54153ded6613c74dd8b026d28c1ea244ad841c136e2d28d92e49a34048d"
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
  file.path(pack, "final_manifest_verification.csv"),
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
  "FINISHING004_SEAL=PASS members=",
  nrow(m),
  " SHA256=",
  sha(target),
  " decision=",
  sha(file.path(base, "decision.md")),
  " acceptance=",
  sha(file.path(base, "internal_report_independent_acceptance.md")),
  " cumulative_audit_seconds=",
  sum(accounting$charged_seconds),
  "\n",
  sep = ""
)
