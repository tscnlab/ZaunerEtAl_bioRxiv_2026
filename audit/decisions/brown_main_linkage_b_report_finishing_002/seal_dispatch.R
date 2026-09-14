# Metadata-only exact dispatch sealing. No model/data execution or author edit.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
central <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_002"
)
prior <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_001"
)
temp <- "/private/tmp/ba018-completion-audit.ekpsA4"
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
mode <- commandArgs(TRUE)
stopifnot(length(mode) == 1L, mode %in% c("seal", "verify"))
target <- file.path(central, "dispatch_manifest.csv")
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
    "BROWN_REPORT_FINISHING_002_DISPATCH=PASS members=",
    nrow(m),
    " SHA256=",
    sha(target),
    "\n",
    sep = ""
  )
  quit(status = 0)
}
stopifnot(!file.exists(target))
archive <- file.path(central, "independent_evidence")
stopifnot(!dir.exists(archive))
dir.create(archive)
copy_files <- function(from, to) {
  stopifnot(!dir.exists(to))
  dir.create(to, recursive = TRUE)
  paths <- list.files(
    from,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE
  )
  paths <- paths[!file.info(paths)$isdir]
  relative <- substring(paths, nchar(from) + 2L)
  dest <- file.path(to, relative)
  for (i in seq_along(paths)) {
    dir.create(dirname(dest[[i]]), recursive = TRUE, showWarnings = FALSE)
    stopifnot(
      !file.exists(dest[[i]]),
      file.copy(paths[[i]], dest[[i]], overwrite = FALSE),
      sha(paths[[i]]) == sha(dest[[i]])
    )
  }
}
copy_files(
  file.path(temp, "internal_recovery_audit_output_001"),
  file.path(archive, "recovery_audit")
)
copy_files(
  file.path(temp, "internal_recovery_audit_execution_001"),
  file.path(archive, "recovery_execution")
)
audit_script <- file.path(temp, "audit_internal_stop_and_reporting_recovery.R")
stopifnot(file.copy(
  audit_script,
  file.path(archive, basename(audit_script)),
  overwrite = FALSE
))
names <- c(
  "figure_candidate_independent",
  "current_report_projections",
  "internal_fixture_cells",
  "results_fixture_cells",
  "methods_fixture_cells",
  "internal_render_structure",
  "internal_render_table_cells",
  "internal_render_images"
)
accounting <- data.frame(
  component = "previous_sealed_accounting",
  basis = file.path(prior, "accounting_summary.json"),
  charged_seconds = jsonlite::read_json(file.path(
    prior,
    "accounting_summary.json"
  ))$cumulative_seconds
)
if (length(accounting$charged_seconds) != 1L)
  stop("Inspect previous accounting schema before seal")
for (name in names) {
  execution <- file.path(temp, paste0(name, "_execution_001"))
  copy_files(execution, file.path(archive, paste0(name, "_execution_001")))
  finish <- jsonlite::read_json(file.path(execution, "finish.json"))
  stopifnot(finish$exit_code == 0L, !finish$timed_out, finish$child_reaped)
  accounting <- rbind(
    accounting,
    data.frame(
      component = name,
      basis = file.path(archive, paste0(name, "_execution_001/finish.json")),
      charged_seconds = finish$elapsed_seconds
    )
  )
}
finish <- jsonlite::read_json(file.path(
  archive,
  "recovery_execution/finish.json"
))
stopifnot(finish$exit_code == 0L, !finish$timed_out, finish$child_reaped)
accounting <- rbind(
  accounting,
  data.frame(
    component = "internal_recovery_audit",
    basis = file.path(archive, "recovery_execution/finish.json"),
    charged_seconds = finish$elapsed_seconds
  )
)
stopifnot(
  !anyDuplicated(accounting$basis),
  sum(accounting$charged_seconds) < 1200
)
write.csv(
  accounting,
  file.path(central, "audit_compute_accounting.csv"),
  row.names = FALSE
)
jsonlite::write_json(
  list(
    charged_seconds = sum(accounting$charged_seconds),
    limit_seconds = 1200,
    additional_fits = 0L,
    additional_draws = 0L,
    report_render_seconds_separately_recorded = 7.207928958989214
  ),
  file.path(central, "accounting_summary.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)
pins <- read.csv(file.path(
  archive,
  "recovery_audit/prospective_source_pins.csv"
))
baseline <- file.path(central, "source_preimages")
dir.create(baseline)
for (i in seq_len(nrow(pins))) {
  stopifnot(sha(pins$path[[i]]) == pins$before_sha256[[i]])
  dest <- file.path(baseline, basename(pins$path[[i]]))
  stopifnot(
    file.copy(pins$path[[i]], dest, overwrite = FALSE),
    sha(dest) == pins$before_sha256[[i]]
  )
}
stop_manifest <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/reporting/internal_stop_001/manifest.csv"
)
stopifnot(
  sha(stop_manifest) ==
    "06c1ea478c45c13bab6ae8f2199c3623189527e36a616af69a748dde03976748"
)
members <- verify(stop_manifest)
paths <- c(
  members$path,
  stop_manifest,
  paste0(dirname(stop_manifest), "/manifest_verification.csv"),
  file.path(
    prior,
    c(
      "decision.md",
      "dispatch_manifest.csv",
      "reader_dependency_review_001.md",
      "accounting_summary.json"
    )
  )
)
paths <- c(
  paths,
  list.files(central, recursive = TRUE, full.names = TRUE, all.files = TRUE)
)
paths <- sort(unique(paths[!file.info(paths)$isdir]))
stopifnot(!target %in% paths)
manifest <- data.frame(
  path = paths,
  bytes = file.info(paths)$size,
  sha256 = unname(vapply(paths, sha, character(1)))
)
write.csv(manifest, target, row.names = FALSE)
replay <- verify(target)
cat(
  "BROWN_REPORT_FINISHING_002_SEAL=PASS members=",
  nrow(replay),
  " SHA256=",
  sha(target),
  " charged_seconds=",
  sum(accounting$charged_seconds),
  "\n",
  sep = ""
)
