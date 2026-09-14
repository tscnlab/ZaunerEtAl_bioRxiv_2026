# File identities, stored flags and execution metadata only. No scientific calculation.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
central <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_001"
)
evidence <- file.path(central, "independent_evidence")
analysis <- file.path(owner, "audit/analyses/brown_adherence")
stage <- file.path(analysis, "main_linkage_b_amendment/stage2")
package <- file.path(stage, "completion_v2/continued_final_package_011")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
hashes <- function(p) {
  u <- unique(p)
  unname(vapply(u, sha, character(1))[match(p, u)])
}
verify <- function(p) {
  m <- read.csv(p)
  stopifnot(
    !anyDuplicated(m$path),
    !p %in% m$path,
    all(file.info(m$path)$size == m$bytes),
    identical(hashes(m$path), m$sha256)
  )
  m
}
mode <- commandArgs(TRUE)
stopifnot(length(mode) == 1L, mode %in% c("seal", "dispatch"))
dispatch_path <- file.path(central, "dispatch_manifest.csv")
if (mode == "dispatch") {
  m <- verify(dispatch_path)
  cat(
    "BROWN_REPORT_DISPATCH=PASS rows=",
    nrow(m),
    " sha=",
    sha(dispatch_path),
    "\n",
    sep = ""
  )
  quit(status = 0)
}
pm <- file.path(package, "final_manifest.csv")
stopifnot(
  sha(pm) == "c1ce90bf88ff3597d6a75419ee331f091d0a867735117e8785973e1f172af696"
)
members <- verify(pm)
stopifnot(nrow(members) == 1705L)
final_checks <- read.csv(file.path(package, "finalization_checks.csv"))
stopifnot(
  nrow(final_checks) == 28L,
  all(final_checks$passed),
  sha(file.path(package, "finalization_checks.csv")) ==
    "b6847a3041d01c969b786eb5d4923e6d91f73fa38e863e9e8fd52fca09a2576d"
)
previous_dispatch <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_stage2_finishing_001/dispatch_manifest.csv"
)
parent <- verify(previous_dispatch)
stopifnot(nrow(parent) == 3846L)
audit_names <- c("r2_independent", "reuse_independent")
check_counts <- c(157L, 166L)
scripts <- c("audit_completed_r2.R", "audit_finishing_reuse_and_exports.R")
audit_finishes <- file.path(
  evidence,
  paste0(audit_names, "_execution_001"),
  "finish.json"
)
audit_runtime <- numeric(2L)
for (i in seq_along(audit_names)) {
  checks <- read.csv(file.path(
    evidence,
    paste0(audit_names[[i]], "_output_001"),
    "checks.csv"
  ))
  finish <- jsonlite::read_json(audit_finishes[[i]])
  stopifnot(
    nrow(checks) == check_counts[[i]],
    all(checks$pass),
    finish$exit_code == 0L,
    !finish$timed_out,
    finish$child_reaped,
    finish$script_sha256 == sha(file.path(evidence, scripts[[i]]))
  )
  audit_runtime[[i]] <- finish$elapsed_seconds
}
runtime <- read.csv(file.path(package, "runtime_and_draw_budget.csv"))
stopifnot(
  nrow(runtime) == 1L,
  runtime$supervised_jobs == 95L,
  runtime$finishing_model_fits == 0L,
  runtime$finishing_draws == 0L,
  runtime$logical_draws == 1500L,
  runtime$attempted_draws == 1750L
)
accounting <- data.frame(
  component = c("owner_supervised_plus_previous_audits", audit_names),
  basis = c(file.path(package, "runtime_and_draw_budget.csv"), audit_finishes),
  charged_seconds = c(runtime$cumulative_seconds, audit_runtime)
)
stopifnot(
  !anyDuplicated(accounting$basis),
  sum(accounting$charged_seconds) < 1200
)
ep <- file.path(
  analysis,
  c(
    "13_cross_state_association_results_amendment.qmd",
    "13_cross_state_association_results_amendment.html",
    "14_cross_state_association_preparation_and_provenance.qmd",
    "14_cross_state_association_preparation_and_provenance.html"
  )
)
ep_hash <- c(
  "9a6f2402f57640fb19319845b7d25f0ade1697dfab0ff262bf6dc5a47b97654e",
  "3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d",
  "577121dbca925e26d47307cd66ff6b02a15e9295b0ad46064accfd8f6b69106d",
  "54e85fe7873a8b54772341ce95241e5dc93ec7ab14aef99f0b1b72773b0f5954"
)
stopifnot(identical(hashes(ep), ep_hash))
config <- file.path(
  analysis,
  c("_quarto.yml", "stage1.css", "stage3_cross_state_association/report.css")
)
config_hash <- c(
  "7b1d2b50c29febafddd7a70e6ff6c7d862debafddb7f27189113f34ab326be66",
  "015c737b6a79359af0d1b4c09c6ccbe731b64704425b143f34b20e57cbde87a2",
  "79846bc9b0b67c1a9845abffbe2c0bcb84ea6d902704f21ef1047fd90ccf97cf"
)
stopifnot(identical(hashes(config), config_hash))
engine <- file.path(
  author,
  "scripts/report_harmonization/repair_gt_html_semantics.R"
)
stopifnot(
  sha(engine) ==
    "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1"
)
new_roots <- file.path(
  analysis,
  "main_linkage_b_amendment",
  c("stage2/reporting", "stage3", "stage4")
)
stopifnot(
  !any(file.exists(new_roots)),
  !any(file.exists(file.path(
    stage,
    c(
      "implementation_and_reconciliation.qmd",
      "implementation_and_reconciliation.html",
      "preflight/computation.lock"
    )
  )))
)
pins <- sort(unique(c(
  ep,
  config,
  engine,
  pm,
  file.path(
    package,
    c(
      "final_manifest_verification.csv",
      "finalization_checks.csv",
      "stage2_handoff.md",
      "author_gate.md"
    )
  ),
  file.path(
    stage,
    c(
      "r2/manifest.csv",
      "reuse/manifest.csv",
      "source_data/manifest.csv",
      "scientific_assessment_finishing.md"
    )
  )
)))
outputs <- file.path(
  central,
  c(
    "input_pins.csv",
    "audit_compute_accounting.csv",
    "accounting_summary.json",
    "dispatch_manifest.csv"
  )
)
stopifnot(!any(file.exists(outputs)))
write.csv(
  data.frame(path = pins, bytes = file.info(pins)$size, sha256 = hashes(pins)),
  outputs[[1L]],
  row.names = FALSE
)
write.csv(accounting, outputs[[2L]], row.names = FALSE)
jsonlite::write_json(
  list(
    authority = "BA-018-REPORT-FINISHING-001",
    supervised_jobs = 95L,
    prior_cumulative_seconds = runtime$cumulative_seconds,
    new_independent_audits_seconds = sum(audit_runtime),
    cumulative_seconds = sum(accounting$charged_seconds),
    maximum_seconds = 1200,
    remaining_seconds = 1200 - sum(accounting$charged_seconds),
    logical_draws = 1500L,
    attempted_draws = 1750L,
    additional_fit_or_draw_authority = FALSE
  ),
  outputs[[3L]],
  auto_unbox = TRUE,
  pretty = TRUE,
  digits = NA
)
local <- list.files(
  central,
  full.names = TRUE,
  recursive = TRUE,
  all.files = TRUE
)
local <- local[!file.info(local)$isdir]
paths <- sort(unique(c(
  parent$path,
  previous_dispatch,
  members$path,
  pins,
  local
)))
stopifnot(!outputs[[4L]] %in% paths)
write.csv(
  data.frame(
    path = paths,
    bytes = file.info(paths)$size,
    sha256 = hashes(paths)
  ),
  outputs[[4L]],
  row.names = FALSE
)
m <- verify(outputs[[4L]])
cat(
  "BROWN_REPORT_RELEASE=PASS members=",
  nrow(m),
  " total_seconds=",
  format(sum(accounting$charged_seconds), digits = 17),
  "\n",
  sep = ""
)
for (p in c(
  file.path(central, "decision.md"),
  file.path(central, "independent_acceptance.md"),
  outputs
))
  cat(basename(p), sha(p), "\n")
