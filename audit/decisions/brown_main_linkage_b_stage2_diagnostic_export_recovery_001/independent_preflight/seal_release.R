stopifnot(as.character(getRversion()) == "4.6.1")
tmp <- "/private/tmp/ba018-diagnostic-recovery.DfiQe9"
central <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
release <- file.path(central, "audit/decisions/brown_main_linkage_b_stage2_diagnostic_export_recovery_001")
sha <- function(p) unname(digest::digest(p, algo = "sha256", file = TRUE))
registry <- read.csv(file.path(tmp, "job_registry_0001.csv"), stringsAsFactors = FALSE)
schema <- lapply(seq_len(nrow(registry)), function(i) {
  r <- registry[i, ]
  g <- read.csv(r$fit_gate_path, stringsAsFactors = FALSE)
  stopifnot(sha(r$fit_gate_path) == r$fit_gate_sha256, nrow(g) == 1L, all(c("model_id", "sample_id", "fit_status") %in% names(g)), g$model_id == sub("\\.rds$", "", basename(r$model_path)), g$sample_id == r$sample_slot, !is.na(g$fit_status), nzchar(g$fit_status))
  data.frame(sample_slot = r$sample_slot, model_id = g$model_id, fit_status = g$fit_status, pass = TRUE)
})
write.csv(do.call(rbind, schema), file.path(tmp, "actual_frozen_schema_checks.csv"), row.names = FALSE)
driver_checks <- read.csv(file.path(tmp, "driver_checks.csv"))
supervisor_checks <- read.csv(file.path(tmp, "supervisor_checks.csv"))
stopifnot(nrow(driver_checks) == 32L, all(driver_checks$pass), nrow(supervisor_checks) == 44L, all(supervisor_checks$pass))
stopifnot(sha(file.path(tmp, "07_run_primary_diagnostics_v2.R")) == "ed06bbdc1257efbbd543dfd2cedd321d2796c2c1d0baad043e279511deeb5428", sha(file.path(tmp, "run_bounded_job_v4.py")) == "c6be41215a27a3ed76f75367336915bbba25537fafa2a4a962de9fa038f994ae")

# Archive the bounded source, logs and summary evidence. All mock fixture files
# remain inventoried, but are not execution inputs or owner copy candidates.
all_tmp <- list.files(tmp, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
all_tmp <- all_tmp[!file.info(all_tmp)$isdir]
stopifnot(all(Sys.readlink(all_tmp) == ""))
write.csv(data.frame(path = all_tmp, sha256 = vapply(all_tmp, sha, character(1)), bytes = unname(file.info(all_tmp)$size)), file.path(tmp, "temporary_audit_inventory.csv"), row.names = FALSE)
archive <- file.path(release, "independent_preflight")
stopifnot(!file.exists(archive))
dir.create(archive)
files <- list.files(tmp, full.names = TRUE, all.files = TRUE, no.. = TRUE)
files <- files[!file.info(files)$isdir]
for (source in files) {
  destination <- file.path(archive, basename(source))
  stopifnot(!file.exists(destination), file.copy(source, destination), sha(source) == sha(destination))
}

# All pre-existing input paths are exact hard pins. The new dispatch does not
# include itself or future receipt/execution files, avoiding a circular seal.
inputs <- read.csv(file.path(tmp, "all_current_input_pins.csv"), stringsAsFactors = FALSE)
stopifnot(!anyDuplicated(inputs$path), all(vapply(inputs$path, sha, character(1)) == inputs$sha256), all(unname(file.info(inputs$path)$size) == inputs$bytes))
new <- list.files(release, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
new <- new[!file.info(new)$isdir]
paths <- sort(unique(c(inputs$path, new)))
manifest_path <- file.path(release, "dispatch_manifest.csv")
stopifnot(!file.exists(manifest_path), !manifest_path %in% paths, all(Sys.readlink(paths) == ""))
manifest <- data.frame(path = paths, sha256 = vapply(paths, sha, character(1)), bytes = unname(file.info(paths)$size))
write.csv(manifest, manifest_path, row.names = FALSE)
check <- read.csv(manifest_path, stringsAsFactors = FALSE)
check$exact <- vapply(check$path, sha, character(1)) == check$sha256 & unname(file.info(check$path)$size) == check$bytes
stopifnot(all(check$exact), !anyDuplicated(check$path), !manifest_path %in% check$path)
write.csv(check, file.path(release, "dispatch_verification.csv"), row.names = FALSE)
cat("BA018_DIAGNOSTIC_RECOVERY_DISPATCH=SEALED members=", nrow(check), " exact=", sum(check$exact), " noncircular=TRUE\n", sep = "")
cat("decision", sha(file.path(release, "decision.md")), "\nmanifest", sha(manifest_path), "\n")
