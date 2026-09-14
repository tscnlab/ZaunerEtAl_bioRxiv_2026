# Non-analytical dispatch inventory and bounded audit-time accounting only.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
base <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_003"
)
prior <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_002"
)
temp <- "/private/tmp/ba018-completion-audit.ekpsA4"
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
    "FINISHING003_DISPATCH=PASS members=",
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
  stopifnot(!dir.exists(to))
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
names <- c(
  "exploratory_tables_fixture_execution_001",
  "exploratory_tables_fixture_execution_002",
  "internal_replacement_structure_execution_001",
  "internal_replacement_cells_execution_001",
  "internal_replacement_images_execution_001",
  "all_report_headings_execution_001",
  "all_report_headings_execution_002",
  "finishing003_recovery_execution_001",
  "finishing003_recovery_execution_002"
)
accounting <- data.frame(
  component = "previous_sealed_accounting",
  basis = file.path(prior, "audit_compute_accounting.csv"),
  charged_seconds = sum(
    read.csv(file.path(prior, "audit_compute_accounting.csv"))$charged_seconds
  )
)
for (n in names) {
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
  "finishing003_recovery_output_001",
  "finishing003_recovery_output_002",
  "all_report_headings_output_001",
  "all_report_headings_output_002"
))
  copy_tree(file.path(temp, n), file.path(archive, n))
for (n in c(
  "audit_finishing_003_recovery.R",
  "audit_finishing_003_recovery_v2.R",
  "audit_complete_report_headings.R",
  "audit_complete_report_headings_v2.R",
  "audit_reader_structure.R",
  "audit_reader_table_bindings.R",
  "audit_embedded_report_figures.R",
  "audit_exploratory_reader_tables.R"
))
  stopifnot(file.copy(
    file.path(temp, n),
    file.path(archive, n),
    overwrite = FALSE
  ))
stopifnot(
  !anyDuplicated(accounting$basis),
  sum(accounting$charged_seconds) < 1200
)
write.csv(
  accounting,
  file.path(base, "audit_compute_accounting.csv"),
  row.names = FALSE
)
stop_manifest <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/reporting/recovery_002/stopped_package/manifest.csv"
)
stopifnot(
  sha(stop_manifest) ==
    "f7700c6d89c3fd7bdbdd9d4998fe9cdf026cd41de038cd9e1c0376175059ac21"
)
members <- verify(stop_manifest)
pins <- read.csv(file.path(
  archive,
  "finishing003_recovery_output_002/exact_transition_pins.csv"
))
stopifnot(identical(
  unname(vapply(pins$path, sha, character(1))),
  pins$before_sha256
))
paths <- unique(c(
  members$path,
  stop_manifest,
  pins$path,
  file.path(
    prior,
    c("decision.md", "dispatch_manifest.csv", "audit_compute_accounting.csv")
  ),
  list.files(base, recursive = TRUE, full.names = TRUE, all.files = TRUE)
))
paths <- sort(paths[!file.info(paths)$isdir])
stopifnot(!target %in% paths)
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
  "FINISHING003_SEAL=PASS members=",
  nrow(m),
  " SHA256=",
  sha(target),
  " decision=",
  sha(file.path(base, "decision.md")),
  " cumulative_audit_seconds=",
  sum(accounting$charged_seconds),
  "\n",
  sep = ""
)
