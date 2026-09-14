shared <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
analysis_root <- file.path(brown, "audit/analyses/brown_adherence")
owner <- "/private/tmp/brown-linkage-b-audit.zheXiZ"
replay <- "/private/tmp/brown-main-linkage-b-central.t3x4Kv"
out <- file.path(shared, "audit/decisions/brown_main_linkage_b_stage1_release")
stopifnot(as.character(getRversion()) == "4.6.1", !dir.exists(out))
stopifnot(!dir.exists(file.path(analysis_root, "main_linkage_b_amendment/stage1")))
sha <- function(p) unname(digest::digest(file = p, algo = "sha256"))
inventory <- function(paths) data.frame(path = paths, bytes = as.numeric(file.info(paths)$size), sha256 = unname(vapply(paths, sha, character(1))), stringsAsFactors = FALSE)
check_manifest <- function(p, n, expected_sha) {
  stopifnot(sha(p) == expected_sha)
  x <- read.csv(p, check.names = FALSE, stringsAsFactors = FALSE)
  stopifnot(nrow(x) == n, !anyDuplicated(x$path), !p %in% x$path, all(file.exists(x$path)))
  z <- inventory(x$path)
  stopifnot(identical(z$sha256, x$sha256), identical(z$bytes, as.numeric(x$bytes)))
  z
}
owner_rows <- check_manifest(file.path(owner, "manifest.csv"), 9L, "89886c2ce89085cec346729717bd787807d31231f6d7879ec93f41dd0a008c24")
fit_rows <- check_manifest(file.path(analysis_root, "stage2_boundary/manifest_BA-EIBB-SENS-LINKAGE-B-F3-R3-Q2-Q1-D0.csv"), 7L, "b723c26e76cf3943cc1729e7d11b82265ce480699e0f4721bdb68a4580ea3bf2")
replay_names <- c("audit_checks.csv", "audit_output.txt", "existing_linkage_b_coverage.csv", "input_identities.csv", "presleep_comparison.csv", "sample_summary.csv")
stopifnot(all(vapply(replay_names, function(f) sha(file.path(owner, f)) == sha(file.path(replay, f)), logical(1))))
brown_pins <- c(
  "stage2/model_frames.rds" = "13ef1ed1e07d055e369b1e7d479285aee38a0587b61c5b87747067c3bc3a6821",
  "stage2/frame_manifest.csv" = "47b94e517c3d5b0781dfebdd225a4a4f4dde178c9eb0ed66dc24fbad39ed837f",
  "stage2_boundary/model_BA-EIBB-SENS-LINKAGE-B-F3-R3-Q2-Q1-D0.rds" = "592d03879523a485f54c8837378ff29c782be20538987e879ec8012ef72c0f75",
  "stage2_boundary/manifest_BA-EIBB-SENS-LINKAGE-B-F3-R3-Q2-Q1-D0.csv" = "b723c26e76cf3943cc1729e7d11b82265ce480699e0f4721bdb68a4580ea3bf2",
  "stage2_boundary/boundary_sensitivity_estimands.rds" = "f4b8d1c61e124096bf2b3d63555a33602d2d0c5bc2c0be68f69da7445ffd1b90",
  "stage2_boundary/boundary_stage2_final_manifest.csv" = "24e0adf52dbc516213cc40f34e27c41dc7fe531553520aae7a22397a6d5bdf97",
  "stage2_boundary/site_free_work_vs_equal_site_amendment/stage2_ba_m6_final_manifest.csv" = "86cbf5d807a2727715b269208bca5177aa38223f1e79163419a2a905f0eb76ea",
  "stage2_cross_state_association/cross_state_stage2_final_manifest.csv" = "ec4549c2aaa07145efbc620ede805f735d3c95e7f047a09707d3eac0ba1fb38b",
  "stage2_cross_state_association/stage2_date_mapping_reconciliation.csv" = "e27a37c657eda5359fb468756027c51d3bb4c296c1a12854be0d297bdf7b1222",
  "stage2_cross_state_association/stage2_historical_linkage_b_reconciliation.csv" = "6c307a08960c15968500612a1b489370289da482083e831f8cfa687e202d9c1f"
)
shared_pins <- c(
  "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds" = "110819d74503c895170552c1f2214aca83de51cadd23bde7525aa821ee0b0e15",
  "audit/decisions/brown_adherence_boundary_stage2_acceptance_stage3_transition.md" = "9fd1c581fcde89a8845c2fabfc47b946e2368da49ca78f2f29c1212bc80de7f7",
  "audit/decisions/brown_adherence_site_daytype_vs_equal_site_stage2_stage3_reopening.md" = "59877990f607cf7d74dcd8e46674b926ed7a6d6ddf8ac030991e1389b02a789a",
  "audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition.md" = "985c865228d392b8721810d33c5fe89cfc73163393b52ce3074752fda2192ebe"
)
pinned_paths <- c(file.path(analysis_root, names(brown_pins)), file.path(shared, names(shared_pins)))
hard_pins <- inventory(pinned_paths)
stopifnot(identical(hard_pins$sha256, unname(c(brown_pins, shared_pins))))
ledger_names <- c("decision_register.csv", "change_log.csv")
ledger_paths <- file.path(shared, "audit/ledgers", ledger_names)
stopifnot(all(vapply(seq_along(ledger_names), function(i) sha(ledger_paths[i]) == sha(file.path(replay, paste0("baseline_", ledger_names[i]))), logical(1))))
decisions <- read.csv(ledger_paths[1], check.names = FALSE, stringsAsFactors = FALSE)
changes <- read.csv(ledger_paths[2], check.names = FALSE, stringsAsFactors = FALSE)
stopifnot(!"BA-017" %in% decisions$decision_id, !"CHG-156" %in% changes$change_id)
report_paths <- file.path(analysis_root, c("07_results.qmd", "07_results.html", "13_cross_state_association_results_amendment.qmd", "13_cross_state_association_results_amendment.html", "14_cross_state_association_preparation_and_provenance.qmd", "14_cross_state_association_preparation_and_provenance.html"))
preservation <- inventory(unique(c(pinned_paths, fit_rows$path, report_paths, file.path(brown, "renv.lock"))))
stopifnot(dir.create(out), dir.create(file.path(out, "baseline")), dir.create(file.path(out, "completed_owner_audit")), dir.create(file.path(out, "completed_central_replay")))
copy_verified <- function(paths, dest) {
  targets <- file.path(dest, basename(paths))
  stopifnot(!any(file.exists(targets)), all(file.copy(paths, targets, overwrite = FALSE)))
  stopifnot(identical(unname(vapply(paths, sha, character(1))), unname(vapply(targets, sha, character(1)))))
  data.frame(original_path = paths, preserved_path = targets, bytes = as.numeric(file.info(targets)$size), sha256 = unname(vapply(targets, sha, character(1))), stringsAsFactors = FALSE)
}
copies <- rbind(
  copy_verified(c(ledger_paths, file.path(shared, "audit/decisions/brown_adherence_main_linkage_b_stage1_reopening.md")), file.path(out, "baseline")),
  copy_verified(c(owner_rows$path, file.path(owner, "manifest.csv")), file.path(out, "completed_owner_audit")),
  copy_verified(list.files(replay, full.names = TRUE), file.path(out, "completed_central_replay"))
)
write.csv(copies, file.path(out, "historical_evidence_copy_inventory.csv"), row.names = FALSE)
write.csv(hard_pins, file.path(out, "frozen_authority_input_pins.csv"), row.names = FALSE)
write.csv(preservation, file.path(out, "owner_preservation_pins.csv"), row.names = FALSE)
write.csv(inventory(file.path(shared, c("audit/report_harmonization/coordination_matrix.csv", "audit/report_harmonization/phase4_corpus_manifest.csv"))), file.path(out, "coordination_preservation.csv"), row.names = FALSE)
writeLines(c(paste("R", getRversion()), paste("digest", packageVersion("digest")), "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript --vanilla /private/tmp/ba017-dispatch.7VdBDq/prepare_release.R", "Read-only artifact identity verification and central administrative evidence copying only. No RDS deserialization, model evaluation, feasibility replay, or scientific calculation."), file.path(out, "release_environment.txt"))
stopifnot(file.copy("/private/tmp/ba017-dispatch.7VdBDq/prepare_release.R", file.path(out, "prepare_release.R")))
cat("BA017_RELEASE_PREPARATION=PASS owner_manifest=9/9 fit_manifest=7/7 replay_identities=6/6 hard_pins=14/14 preservation=", nrow(preservation), " copies=", nrow(copies), " new_stage1_root_absent=TRUE no_feasibility_rerun=TRUE\n", sep = "")
