#!/usr/bin/env Rscript

# One-time atomic promotion of the fully accepted navigation candidate.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(project_root)
source(
  file.path(
    project_root,
    "scripts/report_harmonization/navigation_integration_support.R"
  ),
  local = TRUE
)

evidence_dir <- file.path(project_root, nav_integration_evidence_rel)
candidate_checks <- readr::read_csv(
  file.path(evidence_dir, "candidate_checks_final.csv"),
  show_col_types = FALSE
)
stopifnot(nrow(candidate_checks) == 11L, all(candidate_checks$pass))
production_seal <- readr::read_csv(
  file.path(evidence_dir, "candidate_production_seal.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(production_seal) == 1L,
  production_seal$candidate_checks_passed == 11L,
  production_seal$candidate_checks_total == 11L,
  production_seal$accepted_html_exact == 37L,
  production_seal$accepted_build_members == 1180L,
  production_seal$accepted_build_symlinks == 0L,
  production_seal$relevant_processes == 0L,
  production_seal$loopback_listeners == 0L
)

promotion_marker <- file.path(evidence_dir, "promotion_started.txt")
promotion_record_path <- file.path(evidence_dir, "promotion_execution.csv")
stopifnot(!file.exists(promotion_marker), !file.exists(promotion_record_path))

candidate_root <- trimws(nav_read_text(file.path(evidence_dir, "candidate_root.txt")))
candidate_root <- normalizePath(candidate_root, winslash = "/", mustWork = TRUE)
candidate_build <- file.path(candidate_root, "candidate_build")
promotion_manifest <- readr::read_csv(
  file.path(evidence_dir, "candidate_promotion_manifest.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(promotion_manifest) == 40L,
  !anyDuplicated(promotion_manifest$path),
  all(file.exists(file.path(candidate_build, promotion_manifest$path))),
  all(vapply(
    file.path(candidate_build, promotion_manifest$path),
    nav_sha256_file,
    character(1)
  ) == promotion_manifest$sha256)
)

pre_inventory <- readr::read_csv(
  file.path(evidence_dir, "build_inventory_pre.csv"),
  show_col_types = FALSE
)
live_pre <- nav_inventory_tree(file.path(project_root, "_build/nathealth"))
stopifnot(nav_inventories_identical(pre_inventory, live_pre))
stopifnot(
  nav_sha256_file("audit/report_harmonization/phase4_corpus_manifest.csv") ==
    unname(nav_pinned_identities[[
      "audit/report_harmonization/phase4_corpus_manifest.csv"
    ]])
)

historical <- readr::read_csv(
  file.path(evidence_dir, "historical_phase4_corpus_manifest_pre.csv"),
  show_col_types = FALSE
)
allowlist <- nav_load_authorized_source_allowlist(evidence_dir, historical)
production_protected <- readr::read_csv(
  file.path(evidence_dir, "protected_inventory_production_seal.csv"),
  show_col_types = FALSE
)
capture_authoring_boundary <- function(label) {
  checkpoint <- nav_live_source_checkpoint(historical, project_root)
  drift <- nav_source_drift_audit(checkpoint, allowlist)
  stopifnot(
    all(drift$authorized),
    !length(setdiff(drift$path, allowlist$path))
  )
  protected <- nav_classify_protected_inventory(
    nav_inventory_paths(
      nav_collect_protected_paths(project_root, evidence_dir),
      project_root
    ),
    allowlist$path
  )
  common <- intersect(production_protected$path, protected$path)
  changed <- common[vapply(common, function(path) {
    first <- production_protected[production_protected$path == path, , drop = FALSE]
    second <- protected[protected$path == path, , drop = FALSE]
    !nav_inventories_identical(first, second)
  }, logical(1))]
  stopifnot(
    !length(setdiff(protected$path, production_protected$path)),
    !length(setdiff(production_protected$path, protected$path)),
    !length(setdiff(changed, allowlist$path))
  )
  readr::write_csv(
    checkpoint,
    file.path(
      evidence_dir,
      paste0("live_authoring_source_checkpoint_", label, ".csv")
    )
  )
  readr::write_csv(
    drift,
    file.path(evidence_dir, paste0("authorized_source_drift_", label, ".csv"))
  )
  readr::write_csv(
    protected,
    file.path(evidence_dir, paste0("protected_inventory_", label, ".csv"))
  )
  list(checkpoint = checkpoint, drift = drift, protected = protected)
}

pre_promotion_boundary <- capture_authoring_boundary("pre_promotion")

backup_root <- file.path(candidate_root, "promotion_backup")
dir.create(backup_root, recursive = TRUE, showWarnings = FALSE)
existing_targets <- promotion_manifest$path[
  file.exists(file.path(project_root, "_build/nathealth", promotion_manifest$path))
]
new_targets <- setdiff(promotion_manifest$path, existing_targets)
stopifnot(
  length(existing_targets) == 37L,
  setequal(new_targets, names(nav_candidate_asset_hashes))
)
for (relative in existing_targets) {
  nav_copy_file_exact(
    file.path(project_root, "_build/nathealth", relative),
    file.path(backup_root, relative)
  )
}
backup_manifest <- data.frame(
  path = existing_targets,
  sha256 = vapply(
    file.path(backup_root, existing_targets),
    nav_sha256_file,
    character(1)
  ),
  bytes = vapply(
    file.path(backup_root, existing_targets),
    nav_file_bytes,
    numeric(1)
  ),
  stringsAsFactors = FALSE
)
readr::write_csv(
  backup_manifest,
  file.path(evidence_dir, "promotion_backup_manifest.csv")
)

nav_write_text_atomic(
  paste0(
    "started_utc=",
    format(Sys.time(), tz = "UTC", usetz = TRUE),
    "\n"
  ),
  promotion_marker
)

promotion_ok <- FALSE
on.exit({
  if (!promotion_ok) {
    for (relative in existing_targets) {
      nav_copy_file_exact(
        file.path(backup_root, relative),
        file.path(project_root, "_build/nathealth", relative)
      )
    }
    for (relative in new_targets) {
      target <- file.path(project_root, "_build/nathealth", relative)
      if (file.exists(target) && !dir.exists(target)) unlink(target)
    }
  }
}, add = TRUE)

# Shared assets are installed before HTML so no promoted page can reference a
# missing stylesheet. The 37 HTML files then move as one bounded batch.
promotion_order <- c(
  names(nav_candidate_asset_hashes),
  promotion_manifest$path[promotion_manifest$path %in% existing_targets]
)
stopifnot(length(promotion_order) == 40L, !anyDuplicated(promotion_order))
for (relative in promotion_order) {
  nav_copy_file_exact(
    file.path(candidate_build, relative),
    file.path(project_root, "_build/nathealth", relative)
  )
}

live_post <- nav_inventory_tree(file.path(project_root, "_build/nathealth"))
candidate_inventory <- readr::read_csv(
  file.path(evidence_dir, "candidate_build_inventory.csv"),
  show_col_types = FALSE
)
stopifnot(nav_inventories_identical(live_post, candidate_inventory))
stopifnot(all(vapply(
  file.path(project_root, "_build/nathealth", promotion_manifest$path),
  nav_sha256_file,
  character(1)
) == promotion_manifest$sha256))

post_promotion_boundary <- capture_authoring_boundary("post_promotion")

promotion_ok <- TRUE
promotion_record <- data.frame(
  execution_count = 1L,
  promoted_html = length(existing_targets),
  promoted_new_assets = length(new_targets),
  total_promoted_files = length(promotion_order),
  build_members_before = nrow(live_pre),
  build_members_after = nrow(live_post),
  files_after = sum(live_post$type == "file"),
  directories_after = sum(live_post$type == "directory"),
  symlinks_after = sum(live_post$type == "symlink"),
  authorized_source_drift_pre = nrow(pre_promotion_boundary$drift),
  authorized_source_drift_post = nrow(post_promotion_boundary$drift),
  manifest_still_historical =
    nav_sha256_file("audit/report_harmonization/phase4_corpus_manifest.csv") ==
      unname(nav_pinned_identities[[
        "audit/report_harmonization/phase4_corpus_manifest.csv"
      ]]),
  completed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
readr::write_csv(promotion_record, promotion_record_path)
stopifnot(
  promotion_record$execution_count == 1L,
  promotion_record$promoted_html == 37L,
  promotion_record$promoted_new_assets == 3L,
  promotion_record$build_members_after == 1183L,
  promotion_record$files_after == 874L,
  promotion_record$directories_after == 309L,
  promotion_record$symlinks_after == 0L,
  promotion_record$manifest_still_historical
)

cat(
  paste0(
    "NAVIGATION_PROMOTION=PASS executions=1 html=37 assets=3 ",
    "build=1183 files=874 directories=309 symlinks=0\n"
  )
)
