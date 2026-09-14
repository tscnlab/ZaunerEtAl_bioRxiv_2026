# File/hash-level preparation only; no scientific data calculation.
root <- "/private/tmp/ba018-completion-audit.ekpsA4/chest_support_recovery.i5UqmA"
audit <- dirname(root)
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
stage <- file.path(owner, "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2")
central <- file.path(author, "audit/decisions/brown_main_linkage_b_stage2_chest_support_recovery_001")
.libPaths(c(file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"), .libPaths()))
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(path) unname(digest::digest(path, file = TRUE, algo = "sha256"))
owner_manifest_path <- file.path(stage, "completion_v2/continued_final_package_006/final_manifest.csv")
stopifnot(sha(owner_manifest_path) == "b70906505f0f7951abadaa8b4d813cae3508ab68e10f49e6bca3942c65ac8d19")
owner_manifest <- read.csv(owner_manifest_path)
stopifnot(nrow(owner_manifest) == 1033L, !anyDuplicated(owner_manifest$path),
  !(owner_manifest_path %in% owner_manifest$path),
  identical(unname(vapply(owner_manifest$path, sha, character(1))), owner_manifest$sha256),
  all(file.info(owner_manifest$path)$size == owner_manifest$bytes))
write.csv(data.frame(path = owner_manifest$path, pass = TRUE), file.path(central, "owner_1033_verification.csv"), row.names = FALSE)
stopifnot(all(read.csv(file.path(stage, "completion_v2/continued_final_package_006/finalization_checks.csv"))$pass))
destinations <- c("code/18_construct_chest_b_v2.R", "code/run_bounded_job_v7.py")
sources <- file.path(root, basename(destinations))
map <- data.frame(source_path = sources, destination_path = file.path(stage, destinations),
  sha256 = unname(vapply(sources, sha, character(1))), bytes = unname(file.info(sources)$size))
job <- read.csv(file.path(stage, "preflight/qualified_continuation_001/job_registry_0011.csv"))
job$job_id <- "CONSTRUCT-CHEST-B-SUPPORT-RECOVERY-001"
job$purpose <- "Exact source-identical reconstruction with eight frozen chest sites and all 32 supported cells; no fit"
job$driver_path <- map$destination_path[[1L]]
job$driver_sha256 <- map$sha256[[1L]]
job$output_root <- file.path(stage, "placement/chest_b_frames_recovery_001")
job$preserved_model_input_sha256 <- sha(file.path(stage, "placement/chest_b_frames/model_input.rds"))
job$primary_gate_rewrite <- FALSE
registry_path <- file.path(root, "construction_job_registry.csv")
stopifnot(!file.exists(registry_path), nrow(job) == 1L, !anyNA(job))
write.csv(job, registry_path, row.names = FALSE)
expected_source <- file.path(audit, "chest_guard_checkpoint_001/expected_production_payloads.csv")
for (spec in list(c(registry_path, "construction_job_registry.csv"), c(expected_source, "expected_production_payloads.csv"))) {
  map <- rbind(map, data.frame(source_path = spec[[1L]],
    destination_path = file.path(stage, "preflight/chest_support_recovery_001", spec[[2L]]),
    sha256 = sha(spec[[1L]]), bytes = file.info(spec[[1L]])$size))
}
old_sources <- read.csv(file.path(stage, "preflight/qualified_continuation_001/chest_construction_source_manifest.csv"))
old_payload <- read.csv(file.path(stage, "placement/chest_b_frames/manifest.csv"))
old_leaves <- unique(c(old_sources$path, old_payload$path,
  file.path(stage, "placement/chest_b_frames/manifest.csv"), owner_manifest_path,
  file.path(central, "audit_compute_accounting.csv")))
m <- rbind(data.frame(path = old_leaves, bytes = unname(file.info(old_leaves)$size),
    sha256 = unname(vapply(old_leaves, sha, character(1)))),
  data.frame(path = map$destination_path, bytes = map$bytes, sha256 = map$sha256))
stopifnot(!anyDuplicated(m$path))
source_manifest <- file.path(root, "chest_construction_source_manifest.csv")
write.csv(m, source_manifest, row.names = FALSE)
map <- rbind(map, data.frame(source_path = source_manifest,
  destination_path = file.path(stage, "preflight/chest_support_recovery_001/chest_construction_source_manifest.csv"),
  sha256 = sha(source_manifest), bytes = file.info(source_manifest)$size))
stopifnot(nrow(map) == 5L, !anyDuplicated(map$destination_path), !any(file.exists(map$destination_path)),
  !dir.exists(job$output_root), !dir.exists(file.path(stage, "completion_v2/continued_final_package_007")))

# Retain reproducibility inputs in durable coordinator evidence, preserving bytes.
copy_pairs <- data.frame(source = character(), destination = character())
add_tree <- function(path, name) {
  files <- list.files(path, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  files <- files[!file.info(files)$isdir]
  stopifnot(length(files) > 0L)
  copy_pairs <<- rbind(copy_pairs, data.frame(source = files,
    destination = file.path(central, "independent_audit", name, substring(files, nchar(path) + 2L))))
}
for (name in c("chest_construction_checkpoint_001", "deletion_fit_checkpoint_001", "deletion_reporting_checkpoint_001", "family_checkpoint_001", "chest_guard_checkpoint_001",
  "chest_audit_job_001", "deletion_fit_audit_job_001", "deletion_reporting_audit_job_001", "family_audit_job_001", "chest_guard_audit_job_001")) add_tree(file.path(audit, name), name)
scripts <- c(file.path(audit, c("audit_chest_construction_stop.R", "audit_deletion_fit_package.R", "audit_deletion_reporting.R", "audit_family_grouping_weighting.R", "run_readonly_audit.py")),
  file.path(root, c("audit_prospective_guards.R", "prepare_constructor.R", "18_construct_chest_b_v2.R", "constructor_reversed_original.R", "constructor_exact_changes.json",
    "prepare_supervisor_v7.py", "run_bounded_job_v7.py", "supervisor_v6_reconstructed.py", "supervisor_exact_changes.json", "supervisor_pins.json", "test_supervisor_v7.py", "supervisor_checks.csv", "supervisor_mock_summary.json",
    "construction_job_registry.csv", "chest_construction_source_manifest.csv", "prepare_dispatch_inputs.R")))
copy_pairs <- rbind(copy_pairs, data.frame(source = scripts, destination = file.path(central, "independent_audit/source", basename(scripts))))
stopifnot(!anyDuplicated(copy_pairs$destination), !any(file.exists(copy_pairs$destination)))
for (i in seq_len(nrow(copy_pairs))) {
  dir.create(dirname(copy_pairs$destination[i]), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(copy_pairs$source[i], copy_pairs$destination[i], overwrite = FALSE, copy.date = TRUE),
    sha(copy_pairs$source[i]) == sha(copy_pairs$destination[i]))
}
copy_pairs$sha256 <- unname(vapply(copy_pairs$destination, sha, character(1)))
copy_pairs$bytes <- unname(file.info(copy_pairs$destination)$size)
write.csv(copy_pairs, file.path(central, "independent_evidence_copy_inventory.csv"), row.names = FALSE)
# Use durable coordinator copies as the owner installation sources.
for (i in seq_len(nrow(map))) {
  at <- match(map$source_path[i], copy_pairs$source)
  stopifnot(!is.na(at))
  map$source_path[i] <- copy_pairs$destination[at]
}
write.csv(map, file.path(central, "exact_owner_copy_map.csv"), row.names = FALSE)
write.csv(data.frame(check = c("owner_1033_exact_unique_noncircular", "owner_metadata_finalization_pass", "five_new_destinations_absent",
  "new_constructor_output_absent", "new_final_package007_absent", "source_manifest_unique_noncircular", "durable_audit_copies_exact"), pass = TRUE),
  file.path(central, "release_input_checks.csv"), row.names = FALSE)
print(map[, c("sha256", "bytes")], row.names = FALSE)
cat(sprintf("CHEST_RECOVERY_DISPATCH_INPUTS=PASS owner=1033 new_files=5 source_rows=%d durable_copies=%d\n", nrow(m), nrow(copy_pairs)))
