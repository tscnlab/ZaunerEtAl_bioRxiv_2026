options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
out <- "/private/tmp/ba018-m1-coverage-review.RaumiZ"
hash <- function(p) unname(digest::digest(file = p, algo = "sha256", serialize = FALSE))
manifest <- file.path(root, "estimands/manifest.csv")
m <- read.csv(manifest)
stopifnot(nrow(m) == 23L, !anyDuplicated(m$path), !manifest %in% m$path)
m$observed_sha256 <- unname(vapply(m$path, hash, character(1)))
m$observed_bytes <- as.numeric(file.info(m$path)$size)
m$pass <- m$observed_sha256 == m$sha256 & m$observed_bytes == m$bytes
stopifnot(all(m$pass))
read <- function(p) read.csv(file.path(root, p))
checks <- list()
check <- function(id, test) {
  checks[[length(checks) + 1L]] <<- data.frame(check = id, pass = isTRUE(test))
  stopifnot(isTRUE(test))
}
check("estimand_manifest_23_exact", all(m$pass))
gate <- read("estimands/B_to_B80_claim_gate.csv")
families <- lapply(paste0("multiplicity/BA_M", 1:5, ".csv"), read)
m1 <- families[[1L]]
check("M1_contract_keys", nrow(gate) == 3L && !anyDuplicated(gate$analysis_state) &&
      setequal(gate$state_display, c("Daytime", "Pre-sleep", "Sleep")) &&
      all(gate$contrast == "Free day minus Work day") && all(gate$weighting == "equal_site"))
for (suffix in c("any_valid", "80")) {
  sample <- if (suffix == "any_valid") "primary_any_valid" else "support_80"
  rows <- m1[m1$sample_id == sample, , drop = FALSE]
  idx <- match(gate$analysis_state, rows$analysis_state)
  check(paste0("M1_", suffix, "_matches_full_family"), nrow(rows) == 3L && !anyNA(idx) &&
        all(vapply(c("estimate", "standard_error", "conf_low", "conf_high", "p_value", "p_adjusted"),
                   function(n) max(abs(gate[[paste0(n, "_", suffix)]] - rows[[n]][idx])) < 1e-13, logical(1))))
}
direction <- sign(gate$estimate_any_valid) == sign(gate$estimate_80)
ci_primary <- gate$conf_low_any_valid > 0 | gate$conf_high_any_valid < 0
ci_80 <- gate$conf_low_80 > 0 | gate$conf_high_80 < 0
shift <- 100 * abs(gate$estimate_any_valid - gate$estimate_80)
pass <- direction & (ci_primary == ci_80) & shift <= 2
check("claim_gate_reproduces_exactly", identical(direction, gate$direction_preserved) &&
      identical(ci_primary, gate$interval_exclusion_any_valid) && identical(ci_80, gate$interval_exclusion_80) &&
      identical(ci_primary == ci_80, gate$interval_exclusion_preserved) &&
      max(abs(shift - gate$absolute_shift_percentage_points)) < 1e-12 && identical(pass, gate$passed))
check("only_Presleep_interval_status_fails", identical(gate$state_display[!pass], "Pre-sleep") &&
      all(direction) && all(shift < 2) && sum(ci_primary != ci_80) == 1L)
validation <- read("estimands/validation.csv")
check("exact_single_validation_failure", nrow(validation) == 13L && sum(validation$passed) == 12L &&
      identical(validation$check[!validation$passed], "M1_80_claim_gate"))
quadrature <- read("estimands/quadrature_check.csv")
check("quadrature_stored_comparisons", nrow(quadrature) == 16L && all(quadrature$passed) &&
      all(is.finite(quadrature$maximum_absolute_difference_percentage_points)) &&
      all(quadrature$maximum_absolute_difference_percentage_points <= 0.05))
repro <- read("estimands/historical_B_reproduction.csv")
check("all54_historical_cell_reproductions", nrow(repro) == 54L && all(repro$passed) &&
      all(100 * abs(repro$current_adherence - repro$historical_adherence) <= 0.01))
counts <- c(3L, 3L, 1L, 27L, 54L)
check("all_complete_M1_M5_families", all(vapply(seq_along(families), function(i) {
  z <- families[[i]]
  length(unique(z$sample_id)) == 2L && all(table(z$sample_id) == counts[i]) &&
    all(is.finite(z$p_value)) && all(is.finite(z$p_adjusted))
}, logical(1))))
check("omnibus_full_ranks", all(families[[2L]]$estimable & families[[2L]]$degrees_freedom == 8L) &&
      all(families[[3L]]$estimable & families[[3L]]$degrees_freedom == 16L))
cells <- read("estimands/cell_predictions.csv")
probability_fields <- c("adherence", "all_zero_probability", "all_one_probability", "mixed_probability",
                        "extra_all_zero_probability", "extra_all_one_probability", "beta_binomial_component_probability")
check("both54_cell_grids_probability_bounds", nrow(cells) == 108L && all(table(cells$sample_id) == 54L) &&
      all(is.finite(as.matrix(cells[probability_fields]))) &&
      all(as.matrix(cells[probability_fields]) >= -1e-10 & as.matrix(cells[probability_fields]) <= 1 + 1e-10))
m6 <- read("multiplicity/BA_M6_primary.csv")
m680 <- read("multiplicity/BA_M6_support80.csv")
m6gate <- read("multiplicity/BA_M6_coverage_stability.csv")
check("both27_M6_components_reconcile", nrow(m6) == 27L && nrow(m680) == 27L &&
      all(vapply(list(m6, m680), function(z) all(z$reconciliation_passed) &&
                   all(abs(z$estimate - z$from_M4_minus_M1) < 1e-12) &&
                   all(abs(z$estimate - z$from_free_M5_minus_work_M5) < 1e-12) &&
                   all(abs(z$state_sum) < 1e-12), logical(1))))
check("M6_coverage_claim_gate_passes", nrow(m6gate) == 27L && all(m6gate$fully_estimable) && !any(m6gate$unqualified_claim_blocked))
check("M6_support_has_no_p_FDR", !any(c("p_value", "p_adjusted", "fdr_significant") %in% names(m680)))
finish_path <- file.path(root, "preflight/execution_jobs/DERIVE-PRIMARY-ESTIMANDS-V2/finish.json")
job <- jsonlite::fromJSON(finish_path)
check("sealed_driver_and_supervisor_used", job$driver_sha256 == "729ce699c57d9ab91cc16668c074742cc4929035102a079866390291964037ba" &&
      job$supervisor_sha256 == "1d108833c89ac2815b01075db8d43a1f527c4fabdd09968c4f89a77efe4f1698" &&
      job$exit_code == 1L && !job$timed_out && job$child_reaped)
elapsed <- job$budget_used_before_seconds + job$elapsed_seconds
check("prior_failed_time_retained", abs(job$budget_used_before_seconds - 68.001416874991264) < 1e-12)
check("no_downstream_science_or_lock", !any(file.exists(file.path(root, c("diagnostics", "sensitivity", "decomposition", "preflight/computation.lock", "implementation_and_reconciliation.qmd")))))
display <- data.frame(window = gate$state_display,
  primary_difference_pp = 100 * gate$estimate_any_valid, primary_CI_low_pp = 100 * gate$conf_low_any_valid,
  primary_CI_high_pp = 100 * gate$conf_high_any_valid, coverage80_difference_pp = 100 * gate$estimate_80,
  coverage80_CI_low_pp = 100 * gate$conf_low_80, coverage80_CI_high_pp = 100 * gate$conf_high_80,
  absolute_shift_pp = shift, direction_retained = direction, interval_exclusion_retained = ci_primary == ci_80,
  gate_pass = pass)
write.csv(display, file.path(out, "claim_gate_reconciliation_percentage_points.csv"), row.names = FALSE)
write.csv(m, file.path(out, "estimand_manifest_verification.csv"), row.names = FALSE)
write.csv(do.call(rbind, checks), file.path(out, "independent_checks.csv"), row.names = FALSE)
pins <- c(manifest, file.path(root, "estimands/B_to_B80_claim_gate.csv"), file.path(root, "estimands/validation.csv"),
          file.path(root, "multiplicity/BA_M1.csv"), finish_path)
write.csv(data.frame(path = pins, sha256 = unname(vapply(pins, hash, character(1))), bytes = as.numeric(file.info(pins)$size)),
          file.path(out, "input_pins.csv"), row.names = FALSE)
writeLines(c("Read-only stored-output comparison and gate reconstruction. No model/RDS, prediction, inference derivation, fit, diagnostic or render was executed.",
             sprintf("Accumulated scientific job time now %.15f seconds; all retained, no reset.", elapsed), capture.output(sessionInfo())),
           file.path(out, "scope_and_session.txt"))
stopifnot(identical(unname(vapply(m$path, hash, character(1))), m$sha256))
cat(sprintf("BA018_M1_COVERAGE_AUDIT=PASS checks=%d/%d artifacts=23/23 scientific_validation=12/13 confirmed_failure=M1_Presleep_CI_exclusion accumulated=%.15f manifest=%s\n", length(checks), length(checks), elapsed, hash(manifest)))
print(display, row.names = FALSE, digits = 7)
