# Metadata and checksum verification only. Scientific audits are preserved leaves.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
central <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_stage2_finishing_001"
)
stage <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
)
package <- file.path(stage, "completion_v2/continued_final_package_010")
prior <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_stage2_temporal_transport_recovery_001"
)
evidence <- file.path(central, "independent_evidence")
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
hashes <- function(p) {
  u <- unique(p)
  unname(vapply(u, sha, character(1))[match(p, u)])
}
verify <- function(m, unique = TRUE) {
  stopifnot(
    !anyNA(m[, c("path", "bytes", "sha256")]),
    !unique || !anyDuplicated(m$path),
    all(file.exists(m$path)),
    all(unname(file.info(m$path)$size) == m$bytes),
    identical(hashes(m$path), m$sha256)
  )
}
mode <- commandArgs(TRUE)
stopifnot(length(mode) == 1L, mode %in% c("inputs", "seal", "dispatch"))
dispatch <- file.path(central, "dispatch_manifest.csv")
if (mode == "dispatch") {
  x <- read.csv(dispatch)
  stopifnot(!dispatch %in% x$path)
  verify(x)
  cat(sprintf(
    "BROWN_FINISHING_DISPATCH=PASS rows=%d sha=%s\n",
    nrow(x),
    sha(dispatch)
  ))
  quit(status = 0)
}
mp <- file.path(package, "final_manifest.csv")
stopifnot(
  sha(mp) == "d040431c40b440d9613b0ca2ac7517a55ca558fae9cd5facf88a8d420867111f"
)
om <- read.csv(mp)
stopifnot(nrow(om) == 1466L, !mp %in% om$path)
verify(om)
checks <- read.csv(file.path(package, "finalization_checks.csv"))
stopifnot(nrow(checks) == 34L, all(checks$pass))
protected <- read.csv(file.path(package, "protected_identity_verification.csv"))
stopifnot(
  nrow(protected) == 4533L,
  length(unique(protected$path)) == 2287L,
  all(protected$package010_exact)
)
pm <- data.frame(
  path = protected$path,
  bytes = protected$expected_bytes,
  sha256 = protected$expected_sha256
)
verify(pm, unique = FALSE)
pr <- read.csv(file.path(prior, "dispatch_manifest.csv"))
stopifnot(nrow(pr) == 3654L)
verify(pr)
previous <- read.csv(file.path(
  stage,
  "completion_v2/continued_final_package_009/final_manifest.csv"
))
stopifnot(nrow(previous) == 1312L)
verify(previous)
for (nm in c(
  "temporal_completed_audit_output_003",
  "temporal_diagnostic_audit_output_001"
)) {
  a <- read.csv(file.path(evidence, nm, "checks.csv"))
  stopifnot(nrow(a) == if (grepl("diagnostic", nm)) 604L else 60L, all(a$pass))
}
jobs <- list.files(
  file.path(stage, "preflight/execution_jobs"),
  pattern = "finish.json$",
  recursive = TRUE,
  full.names = TRUE
)
stopifnot(length(jobs) == 91L)
j <- lapply(jobs, jsonlite::read_json)
elapsed <- sum(vapply(j, function(x) x$elapsed_seconds, numeric(1)))
stopifnot(
  sum(vapply(j, function(x) x$exit_code != 0L, logical(1))) == 8L,
  all(vapply(
    j,
    function(x) isTRUE(x$child_reaped) && !isTRUE(x$timed_out),
    logical(1)
  ))
)
old_account <- read.csv(file.path(prior, "audit_compute_accounting.csv"))
old_debit <- sum(old_account$charged_seconds)
stopifnot(abs(old_debit - 66.58152158500906) < 1e-10)
execution_names <- c(
  "temporal_completed_audit_execution_001",
  "temporal_diagnostic_audit_execution_001",
  "temporal_completed_audit_execution_002",
  "temporal_completed_audit_execution_003"
)
expected_exit <- c(1L, 0L, 1L, 0L)
finishes <- file.path(evidence, execution_names, "finish.json")
aj <- lapply(finishes, jsonlite::read_json)
stopifnot(
  identical(vapply(aj, function(x) x$exit_code, integer(1)), expected_exit),
  all(vapply(
    aj,
    function(x) isTRUE(x$child_reaped) && !isTRUE(x$timed_out),
    logical(1)
  ))
)
scripts <- c(
  "audit_completed_temporal.R",
  "audit_completed_temporal_diagnostic_tables.R",
  "audit_completed_temporal_v2.R",
  "audit_completed_temporal_v3.R"
)
stopifnot(identical(
  hashes(file.path(evidence, scripts)),
  vapply(aj, function(x) x$script_sha256, character(1))
))
account <- data.frame(
  component = c("previous_fixed_audits", execution_names),
  basis = c(file.path(prior, "audit_compute_accounting.csv"), finishes),
  charged_seconds = c(
    old_debit,
    vapply(aj, function(x) x$elapsed_seconds, numeric(1))
  )
)
debit <- sum(account$charged_seconds)
stopifnot(
  elapsed + debit < 1200,
  !anyDuplicated(account$component),
  !anyDuplicated(account$basis)
)
draw <- read.csv(file.path(package, "diagnostic_draw_accounting.csv"))
stopifnot(
  nrow(draw) == 1L,
  draw$logical_draws == 1500L,
  draw$attempted_draws == 1750L,
  draw$remaining_logical_draws == 0L
)
absent <- file.path(
  stage,
  c(
    "code/36_finishing_contract.R",
    "code/37_verify_finishing_interfaces.R",
    "code/38_derive_r2_shapley.R",
    "code/39_verify_exploratory_reuse.R",
    "code/40_export_finishing_sources.R",
    "code/run_bounded_job_v11.py",
    "preflight/analysis_finishing_001",
    "tests/analysis_finishing_001",
    "r2",
    "reuse",
    "source_data",
    "scientific_assessment_finishing.md",
    "completion_v2/continued_final_package_011",
    "preflight/computation.lock"
  )
)
stopifnot(!any(file.exists(absent)))
endpoints <- file.path(
  owner,
  paste0(
    "audit/analyses/brown_adherence/",
    c(
      "13_cross_state_association_results_amendment.qmd",
      "13_cross_state_association_results_amendment.html",
      "14_cross_state_association_preparation_and_provenance.qmd",
      "14_cross_state_association_preparation_and_provenance.html"
    )
  )
)
expected <- c(
  "9a6f2402f57640fb19319845b7d25f0ade1697dfab0ff262bf6dc5a47b97654e",
  "3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d",
  "577121dbca925e26d47307cd66ff6b02a15e9295b0ad46064accfd8f6b69106d",
  "54e85fe7873a8b54772341ce95241e5dc93ec7ab14aef99f0b1b72773b0f5954"
)
stopifnot(identical(hashes(endpoints), expected))
if (mode == "inputs") {
  outputs <- file.path(
    central,
    c(
      "audit_compute_accounting.csv",
      "accounting_summary.json",
      "reader_preservation_pins.csv",
      "independent_input_verification.csv"
    )
  )
  stopifnot(!any(file.exists(outputs)))
  write.csv(account, outputs[[1L]], row.names = FALSE)
  jsonlite::write_json(
    list(
      authority = "BA-018-ANALYSIS-FINISHING-001",
      supervised_jobs = length(j),
      supervised_seconds = elapsed,
      previous_fixed_debit_seconds = old_debit,
      new_audit_seconds = sum(account$charged_seconds[-1L]),
      fixed_debit_seconds = debit,
      cumulative_seconds = elapsed + debit,
      maximum_seconds = 1200,
      remaining_seconds = 1200 - elapsed - debit,
      logical_draws = 1500L,
      attempted_draws = 1750L,
      diagnostic_draws_remaining = 0L
    ),
    outputs[[2L]],
    pretty = TRUE,
    auto_unbox = TRUE,
    digits = NA
  )
  write.csv(
    data.frame(
      path = endpoints,
      bytes = file.info(endpoints)$size,
      sha256 = expected
    ),
    outputs[[3L]],
    row.names = FALSE
  )
  labels <- c(
    "package010_1466",
    "finalization34",
    "protected4533_unique2287",
    "previous1312",
    "prior_dispatch3654",
    "temporal_saved_output60",
    "diagnostic604",
    "91_histories_eight_failures",
    "all_children_reaped",
    "four_audits_two_stops_preserved",
    "runtime_charged_once",
    "1500_logical_1750_attempted_no_remaining_draw",
    "absent_targets",
    "reader_four_pins"
  )
  write.csv(
    data.frame(check = labels, pass = TRUE),
    outputs[[4L]],
    row.names = FALSE
  )
  cat(sprintf(
    "BROWN_FINISHING_INPUTS=PASS checks=%d jobs=%d debit=%.17g total=%.17g remaining=%.17g\n",
    length(labels),
    length(j),
    debit,
    elapsed + debit,
    1200 - elapsed - debit
  ))
} else {
  stopifnot(!file.exists(dispatch))
  saved <- jsonlite::read_json(file.path(central, "accounting_summary.json"))
  stopifnot(
    abs(saved$fixed_debit_seconds - debit) < 1e-10,
    abs(saved$cumulative_seconds - elapsed - debit) < 1e-10
  )
  local <- list.files(central, recursive = TRUE, full.names = TRUE)
  local <- local[!file.info(local)$isdir]
  paths <- sort(unique(c(
    om$path,
    mp,
    pm$path,
    pr$path,
    file.path(prior, "dispatch_manifest.csv"),
    previous$path,
    endpoints,
    jobs,
    local
  )))
  stopifnot(!dispatch %in% paths)
  out <- data.frame(
    path = paths,
    bytes = file.info(paths)$size,
    sha256 = hashes(paths)
  )
  write.csv(out, dispatch, row.names = FALSE)
  verify(read.csv(dispatch))
  cat(sprintf(
    "BROWN_FINISHING_SEAL=PASS rows=%d sha=%s\n",
    nrow(out),
    sha(dispatch)
  ))
}
