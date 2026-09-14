#!/usr/bin/env Rscript

# Seal the fully checked candidate and the exact pre-promotion boundary. This
# script is read-only with respect to the accepted website and all authoring
# sources.

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
seal_path <- file.path(evidence_dir, "candidate_production_seal.csv")
stopifnot(!file.exists(seal_path))

historical_path <- file.path(
  evidence_dir,
  "historical_phase4_corpus_manifest_pre.csv"
)
historical <- readr::read_csv(historical_path, show_col_types = FALSE)
manifest_path <- "audit/report_harmonization/phase4_corpus_manifest.csv"
stopifnot(
  nrow(historical) == 37L,
  nav_sha256_file(historical_path) == unname(nav_pinned_identities[[manifest_path]]),
  nav_sha256_file(manifest_path) == nav_sha256_file(historical_path)
)

candidate_checks <- readr::read_csv(
  file.path(evidence_dir, "candidate_checks_final.csv"),
  show_col_types = FALSE
)
promotion_manifest_path <- file.path(
  evidence_dir,
  "candidate_promotion_manifest.csv"
)
promotion_manifest <- readr::read_csv(
  promotion_manifest_path,
  show_col_types = FALSE
)
candidate_root <- trimws(nav_read_text(file.path(evidence_dir, "candidate_root.txt")))
candidate_root <- normalizePath(candidate_root, winslash = "/", mustWork = TRUE)
candidate_build <- file.path(candidate_root, "candidate_build")
candidate_inventory <- nav_inventory_tree(candidate_build)
sealed_candidate_paths <- file.path(candidate_build, promotion_manifest$path)
stopifnot(
  nrow(candidate_checks) == 11L,
  all(candidate_checks$pass),
  nrow(promotion_manifest) == 40L,
  !anyDuplicated(promotion_manifest$path),
  all(file.exists(sealed_candidate_paths)),
  all(vapply(sealed_candidate_paths, nav_sha256_file, character(1)) ==
    promotion_manifest$sha256),
  nrow(candidate_inventory) == 1183L,
  sum(candidate_inventory$type == "symlink") == 0L
)

pre_build <- readr::read_csv(
  file.path(evidence_dir, "build_inventory_pre.csv"),
  show_col_types = FALSE
)
live_build <- nav_inventory_tree(file.path(project_root, "_build/nathealth"))
routes <- vapply(historical$expected_html, nav_html_route, character(1))
html_live <- vapply(historical$expected_html, nav_sha256_file, character(1))
stopifnot(
  nav_inventories_identical(pre_build, live_build),
  nrow(live_build) == 1180L,
  sum(live_build$type == "symlink") == 0L,
  all(html_live == historical$html_sha256),
  setequal(promotion_manifest$path[seq_len(37L)], routes),
  setequal(
    promotion_manifest$path,
    c(routes, names(nav_candidate_asset_hashes))
  )
)

allowlist <- nav_load_authorized_source_allowlist(evidence_dir, historical)
source_checkpoint <- nav_live_source_checkpoint(historical, project_root)
source_drift <- nav_source_drift_audit(source_checkpoint, allowlist)
stopifnot(
  all(source_drift$authorized),
  !length(setdiff(source_drift$path, allowlist$path))
)
readr::write_csv(
  source_checkpoint,
  file.path(evidence_dir, "live_authoring_source_checkpoint_production_seal.csv")
)
readr::write_csv(
  source_drift,
  file.path(evidence_dir, "authorized_source_drift_production_seal.csv")
)

protected_pre <- readr::read_csv(
  file.path(evidence_dir, "protected_inventory_pre.csv"),
  show_col_types = FALSE
)
protected_live <- nav_classify_protected_inventory(
  nav_inventory_paths(
    nav_collect_protected_paths(project_root, evidence_dir),
    project_root
  ),
  allowlist$path
)
readr::write_csv(
  protected_live,
  file.path(evidence_dir, "protected_inventory_production_seal.csv")
)
common <- intersect(protected_pre$path, protected_live$path)
changed <- common[vapply(common, function(path) {
  first <- protected_pre[protected_pre$path == path, , drop = FALSE]
  second <- protected_live[protected_live$path == path, , drop = FALSE]
  !nav_inventories_identical(first, second)
}, logical(1))]
stopifnot(
  !length(setdiff(protected_live$path, protected_pre$path)),
  !length(setdiff(protected_pre$path, protected_live$path)),
  !length(setdiff(changed, allowlist$path))
)

ps_output <- system2(
  "/bin/ps",
  c("-axo", "pid=,command="),
  stdout = TRUE,
  stderr = TRUE
)
ps_status <- nav_parse_command_status(ps_output)
self_pattern <- sprintf("^\\s*%d\\s+", Sys.getpid())
process_pattern <- paste0(
  "^\\s*[0-9]+\\s+(?:\\S*/)?(?:R|Rscript|quarto|pandoc)(?:\\s|$)|",
  "post_render_gt_html_semantics|python(?:3)?\\s+-m\\s+http\\.server|",
  "build_navigation_shell_candidate|promote_navigation_candidate|",
  "reseal_navigation_manifest"
)
relevant_processes <- ps_output[
  grepl(process_pattern, ps_output, ignore.case = TRUE, perl = TRUE) &
    !grepl(self_pattern, ps_output, perl = TRUE)
]
lsof_rows <- unlist(lapply(c("55009", "56925"), function(port) {
  suppressWarnings(system2(
    "/usr/sbin/lsof",
    c("-nP", paste0("-iTCP:", port), "-sTCP:LISTEN"),
    stdout = TRUE,
    stderr = TRUE
  ))
}), use.names = FALSE)
writeLines(
  c(
    sprintf("ps_status=%d", ps_status),
    if (length(relevant_processes)) relevant_processes else "NO_RELEVANT_PROCESS",
    if (length(lsof_rows)) lsof_rows else "NO_CANDIDATE_OR_PREVIEW_LISTENER"
  ),
  file.path(evidence_dir, "production_seal_process_inventory.txt"),
  useBytes = TRUE
)
stopifnot(ps_status == 0L, !length(relevant_processes), !length(lsof_rows))

seal <- data.frame(
  candidate_checks_passed = sum(candidate_checks$pass),
  candidate_checks_total = nrow(candidate_checks),
  candidate_promotion_manifest_sha256 = nav_sha256_file(promotion_manifest_path),
  candidate_build_members = nrow(candidate_inventory),
  candidate_build_symlinks = sum(candidate_inventory$type == "symlink"),
  accepted_html_exact = sum(html_live == historical$html_sha256),
  accepted_build_members = nrow(live_build),
  accepted_build_symlinks = sum(live_build$type == "symlink"),
  authorized_source_drift_paths = nrow(source_drift),
  authorized_source_allowlist_sha256 = nav_sha256_file(file.path(
    evidence_dir,
    "authorized_concurrent_source_allowlist.csv"
  )),
  relevant_processes = length(relevant_processes),
  loopback_listeners = length(lsof_rows),
  sealed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
readr::write_csv(seal, seal_path)

cat(sprintf(
  paste0(
    "NAVIGATION_PRODUCTION_BOUNDARY=SEALED checks=11/11 candidate=1183 ",
    "accepted_html=37/37 accepted_build=1180 source_drift=%d symlinks=0\n"
  ),
  nrow(source_drift)
))
