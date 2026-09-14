stopifnot(as.character(getRversion()) == "4.6.1")
root <- "/private/tmp/ba018-diagnostic-recovery.DfiQe9"
stage2 <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
sha <- function(p) unname(digest::digest(p, algo = "sha256", file = TRUE))
read_text <- function(p) readChar(p, file.info(p)$size, useBytes = TRUE)
driver <- file.path(stage2, "code/07_run_primary_diagnostics.R")
stopifnot(sha(driver) == "20c8a54701b7cd1772ce78aa5b18588dfa9459d08a13dd879ac4716ba58eb5f3")
original <- read_text(driver)
changes <- list(
  list(
    old = 'job_id <- paste0("DIAGNOSTICS-", key)',
    new = paste(c(
      'job_id <- if (key == "PRIMARY-ANY") {',
      '  "DIAGNOSTICS-PRIMARY-ANY-RECOVERY-001"',
      '} else {',
      '  "DIAGNOSTICS-PRIMARY-80"',
      '}'
    ), collapse = "\n")
  ),
  list(
    old = 'registry_root <- file.path(stage2_root, "preflight/qualified_continuation_001")',
    new = paste(c('registry_root <- file.path(', '  stage2_root,', '  "preflight/diagnostic_export_recovery_001"', ')'), collapse = "\n")
  ),
  list(old = '"07_run_primary_diagnostics.R"', new = '"07_run_primary_diagnostics_v2.R"'),
  list(
    old = '  file.path(registry_root, "diagnostic_seed_registry.csv"),',
    new = paste(c(
      '  file.path(',
      '    stage2_root,',
      '    "preflight/qualified_continuation_001/diagnostic_seed_registry.csv"',
      '  ),'
    ), collapse = "\n")
  ),
  list(
    old = 'result <- derive_diagnostics(sample_id, model_path)',
    new = paste(c(
      '# Check the frozen metadata schema before any predictive or residual work.',
      'fit_gate_path <- file.path(',
      '  stage2_root,',
      '  "models",',
      '  paste0("BA-LB-", key, "_fit_gate.csv")',
      ')',
      'stopifnot(sha256(fit_gate_path) == job$fit_gate_sha256)',
      'frozen_fit_gate <- read.csv(fit_gate_path, stringsAsFactors = FALSE)',
      'stopifnot(',
      '  is.data.frame(frozen_fit_gate),',
      '  nrow(frozen_fit_gate) == 1L,',
      '  all(c("model_id", "sample_id", "fit_status") %in% names(frozen_fit_gate)),',
      '  identical(as.character(frozen_fit_gate$model_id), paste0("BA-LB-", key)),',
      '  identical(as.character(frozen_fit_gate$sample_id), sample_slot),',
      '  length(frozen_fit_gate$fit_status) == 1L,',
      '  !is.na(frozen_fit_gate$fit_status),',
      '  nzchar(as.character(frozen_fit_gate$fit_status))',
      ')',
      'result <- derive_diagnostics(sample_id, model_path)',
      '# Retain the unmodified return before validation, metadata or table export.',
      'lb_save_rds(',
      '  result,',
      '  paste0(output_prefix, "/raw_diagnostic_checkpoint.rds")',
      ')',
      'stopifnot(',
      '  is.data.frame(result$bundle$fit_gate),',
      '  nrow(result$bundle$fit_gate) == 1L,',
      '  "fit_status" %in% names(result$bundle$fit_gate),',
      '  identical(',
      '    as.character(result$bundle$fit_gate$fit_status),',
      '    as.character(frozen_fit_gate$fit_status)',
      '  )',
      ')'
    ), collapse = "\n")
  ),
  list(old = 'status = as.character(result$bundle$fit_gate$status)', new = 'status = as.character(result$bundle$fit_gate$fit_status)')
)
candidate <- original
for (change in changes) {
  occurrences <- gregexpr(change$old, candidate, fixed = TRUE)[[1L]]
  stopifnot(length(occurrences) == 1L, occurrences > 0)
  candidate <- sub(change$old, change$new, candidate, fixed = TRUE)
}
path <- file.path(root, "07_run_primary_diagnostics_v2.R")
stopifnot(!file.exists(path))
writeChar(candidate, path, eos = NULL, useBytes = TRUE)
reversed <- candidate
for (change in rev(changes)) reversed <- sub(change$new, change$old, reversed, fixed = TRUE)
stopifnot(identical(reversed, original))
writeChar(reversed, file.path(root, "reconstructed_07_run_primary_diagnostics.R"), eos = NULL, useBytes = TRUE)
saveRDS(changes, file.path(root, "exact_driver_changes.rds"))
invisible(parse(path))

# Version only routing/provenance. Preserve all original seeds, models and roles.
old_registry <- read.csv(file.path(stage2, "preflight/qualified_continuation_001/job_registry_0001.csv"), stringsAsFactors = FALSE)
registry <- old_registry
registry$job_id[registry$sample_slot == "B_any"] <- "DIAGNOSTICS-PRIMARY-ANY-RECOVERY-001"
registry$driver_path <- file.path(stage2, "code/07_run_primary_diagnostics_v2.R")
registry$driver_sha256 <- sha(path)
registry$fit_gate_path <- sub("\\.rds$", "_fit_gate.csv", registry$model_path)
registry$fit_gate_sha256 <- vapply(registry$fit_gate_path, sha, character(1))
registry$recovery_of <- ifelse(registry$sample_slot == "B_any", "DIAGNOSTICS-PRIMARY-ANY", "")
registry$previous_attempted_draws <- ifelse(registry$sample_slot == "B_any", 250L, 0L)
registry$new_attempted_draws <- 250L
registry$maximum_total_attempted_draws <- 1750L
registry$maximum_logical_final_draws <- 1500L
registry$checkpoint_path <- file.path(registry$output_directory, "raw_diagnostic_checkpoint.rds")
stopifnot(nrow(registry) == 2L, !anyDuplicated(registry$job_id), all(registry$diagnostic_draws == 250L))
write.csv(registry, file.path(root, "job_registry_0001.csv"), row.names = FALSE)
write.csv(data.frame(change = seq_along(changes), description = c("unique recovery job", "new registry root", "new driver self-pin", "unchanged historical seed source", "schema gate and immediate raw checkpoint", "correct fit-status field")), file.path(root, "driver_change_inventory.csv"), row.names = FALSE)
cat("PREPARED", sha(path), file.info(path)$size, "reverse=exact changes=6\n")
