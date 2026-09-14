# Non-circular seal of the retrospective process disposition and exact evidence.
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
base <- file.path(scope, "process_disposition")
work <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage3/reporting/finishing_007"
)
temp <- "/private/tmp/ba018-completion-audit.ekpsA4"
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
target <- file.path(base, "manifest.csv")
verify <- function(p) {
  m <- read.csv(p, check.names = FALSE)
  stopifnot(
    !anyDuplicated(m$path),
    !p %in% m$path,
    all(file.info(m$path)$size == m$bytes),
    identical(unname(vapply(m$path, sha, character(1))), m$sha256)
  )
  m
}
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L, args[1] %in% c("seal", "verify"))
if (args[1] == "verify") {
  m <- verify(target)
  cat(
    "PROCESS_DISPOSITION=PASS rows=",
    nrow(m),
    " sha=",
    sha(target),
    "\n",
    sep = ""
  )
  quit(status = 0)
}
stopifnot(!file.exists(target))
deviation <- file.path(work, "process_deviation/manifest.csv")
dm <- verify(deviation)
executions <- c(
  "results007_brief_raw_execution_001",
  "results007_headings_raw_execution_001",
  "results007_inline_context_raw_execution_001",
  "results007_sequence_execution_001",
  "results007_prerender_preservation_execution_001"
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
      file.copy(p, destination, overwrite = FALSE),
      sha(p) == sha(destination)
    )
  }
}
accounting <- data.frame(
  component = "previous_sealed_accounting",
  basis = file.path(scope, "audit_compute_accounting.csv"),
  charged_seconds = sum(
    read.csv(file.path(scope, "audit_compute_accounting.csv"))$charged_seconds
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
  "audit_results007_brief.R",
  "audit_results007_headings.R",
  "audit_results007_inline_context.R",
  "audit_results007_sequence.R",
  "audit_resolved_preservation.R"
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
paths <- unique(c(
  dm$path,
  deviation,
  file.path(work, "pre_render_gate_v3/checks.csv"),
  file.path(work, "render/raw_results_render.html"),
  file.path(scope, c("decision.md", "dispatch_manifest.csv")),
  list.files(base, recursive = TRUE, full.names = TRUE, all.files = TRUE)
))
paths <- sort(paths[!file.info(paths)$isdir])
stopifnot(!target %in% paths, !any(startsWith(paths, "/private/tmp/")))
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
  "PROCESS_DISPOSITION_SEAL=PASS rows=",
  nrow(m),
  " manifest=",
  sha(target),
  " decision=",
  sha(file.path(base, "decision.md")),
  " audit_seconds=",
  sum(accounting$charged_seconds),
  "\n",
  sep = ""
)
