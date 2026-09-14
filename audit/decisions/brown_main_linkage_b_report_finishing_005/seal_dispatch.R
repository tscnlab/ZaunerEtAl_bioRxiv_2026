# Exact infrastructure inventory and cumulative audit accounting, no analysis.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
base <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_005"
)
prior <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_004"
)
temp <- "/private/tmp/ba018-completion-audit.ekpsA4"
brown <- file.path(owner, "audit/analyses/brown_adherence")
pack <- file.path(
  brown,
  "main_linkage_b_amendment/stage3/reporting/finishing_004/consolidated_package"
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
    "FINISHING005_DISPATCH=PASS members=",
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
  "internal003_inline_execution_001",
  paste0(
    "results004_",
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
  "report_format_recovery_execution_001",
  "svg_embedding_execution_001",
  "svg_embedding_execution_002",
  "finishing004_package_execution_001"
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
  output <- sub("_execution_", "_output_", n, fixed = TRUE)
  copy_tree(file.path(temp, output), file.path(archive, output))
}
for (n in c(
  "audit_non_circular_manifest.R",
  "audit_report_format_and_raincloud_recovery.R",
  "audit_svg_embedding_preflight.R",
  "audit_reader_mermaid.R",
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
# Reconstruct the exact failed static-probe version from its two-line correction.
v <- readLines(file.path(archive, "audit_svg_embedding_preflight.R"))
v <- v[v != '    paste0("--output=", shQuote(html))']
v[
  v == '    "--metadata=title:Frozen-SVG-preview",'
] <- '    "--metadata=title:Frozen-SVG-preview"'
v[v == '  stdout = file.path(out, "pandoc_stdout.log"),'] <- '  stdout = html,'
failed <- file.path(archive, "audit_svg_embedding_preflight_failed_001.R")
writeLines(v, failed, useBytes = TRUE)
stopifnot(
  sha(failed) ==
    "12f4817acdd48ccb2b031ddb9bd16f1d8f4b53d724870199bdef686d383664fb"
)
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
    "02abd67794a5acf56f328e037a16efe46fd4e42b284a331e467cba9a22fc14f1"
)
m <- verify(owner_manifest)
stopifnot(nrow(m) == 506L)
transitions <- read.csv(file.path(
  archive,
  "report_format_recovery_output_001/exact_transition_pins.csv"
))
stopifnot(
  nrow(transitions) == 5L,
  identical(
    unname(vapply(transitions$path, sha, character(1))),
    transitions$before_sha256
  ),
  all(file.info(transitions$path)$size == transitions$before_bytes)
)
leaf_path <- file.path(
  brown,
  "main_linkage_b_amendment/stage3/evidence/report_finishing_001/reader_input_manifest.csv"
)
leaf <- read.csv(leaf_path)
leaf_paths <- file.path(brown, leaf$relative_path)
stopifnot(
  nrow(leaf) == 211L,
  !anyDuplicated(leaf_paths),
  identical(unname(vapply(leaf_paths, sha, character(1))), leaf$sha256),
  all(file.info(leaf_paths)$size == leaf$bytes)
)
extra <- file.path(
  brown,
  c(
    "14_cross_state_association_preparation_and_provenance.qmd",
    "14_cross_state_association_preparation_and_provenance.html"
  )
)
stopifnot(identical(
  unname(vapply(extra, sha, character(1))),
  c(
    "4009da02e9239835a0b3a74381472034bc5d478f5b7491e73e80ce88548c4272",
    "54e85fe7873a8b54772341ce95241e5dc93ec7ab14aef99f0b1b72773b0f5954"
  )
))
paths <- unique(c(
  m$path,
  owner_manifest,
  file.path(pack, "final_manifest_verification.csv"),
  transitions$path,
  leaf_path,
  leaf_paths,
  extra,
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
  "FINISHING005_SEAL=PASS members=",
  nrow(m),
  " manifest=",
  sha(target),
  " decision=",
  sha(file.path(base, "decision.md")),
  " cumulative_audit_seconds=",
  sum(accounting$charged_seconds),
  "\n",
  sep = ""
)
