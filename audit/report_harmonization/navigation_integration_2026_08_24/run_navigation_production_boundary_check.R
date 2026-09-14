#!/usr/bin/env Rscript

# Fresh R 4.6.1 production-boundary check under the centrally sealed H09
# source/display concurrence. This script writes only navigation evidence.

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
checks_path <- file.path(evidence_dir, "candidate_production_boundary_checks.csv")
stopifnot(!file.exists(seal_path), !file.exists(checks_path))

checks <- list()
add_check <- function(check_id, pass, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check_id = check_id,
    pass = isTRUE(pass),
    detail = as.character(detail),
    stringsAsFactors = FALSE
  )
}

central_hashes <- c(
  "navigation_production_concurrence_after_h09_source_display_package.md" =
    "a1d5a77c5c601edc8e8ee2f43c53f8e5db27aa568527b8ef273e9683b25083ec",
  "h09_concurrent_package_production_allowlist.csv" =
    "87ce3dccbc73322fb8ce3ff7dcd5df860dd96444b0918e077e39ca3b628e18b5",
  "navigation_production_concurrence_manifest.csv" =
    "a5b8632527d252334e8af4b18a22d2a77fb8718fdf9dfcc341e40162abd2b102"
)
central_paths <- file.path(evidence_dir, names(central_hashes))
central_exact <- all(vapply(central_paths, nav_sha256_file, character(1)) ==
  unname(central_hashes))
central_manifest <- readr::read_csv(
  file.path(evidence_dir, "navigation_production_concurrence_manifest.csv"),
  show_col_types = FALSE
)
central_members <- file.path(project_root, central_manifest$path)
central_manifest_exact <- nrow(central_manifest) == 14L &&
  !anyDuplicated(central_manifest$path) &&
  !nav_relative_to(
    file.path(evidence_dir, "navigation_production_concurrence_manifest.csv"),
    project_root
  ) %in% central_manifest$path &&
  all(file.exists(central_members)) &&
  !any(dir.exists(central_members)) &&
  !any(nzchar(Sys.readlink(central_members))) &&
  all(vapply(central_members, nav_sha256_file, character(1)) ==
    central_manifest$sha256) &&
  all(vapply(central_members, nav_file_bytes, numeric(1)) ==
    central_manifest$bytes)
add_check(
  "central_concurrence",
  central_exact && central_manifest_exact,
  "central_files=3/3 concurrence_manifest=14/14 non_circular=TRUE"
)

promotion_script_path <-
  "scripts/report_harmonization/promote_navigation_candidate_once.R"
promotion_script_exact <-
  nav_sha256_file(promotion_script_path) ==
    "d96b8601b3b67fa4ed97c84ebc241e6ffbffd1a118839d2d0353bc5efa405d06" &&
  nav_file_bytes(promotion_script_path) == 8567
add_check(
  "promotion_script_exact",
  promotion_script_exact,
  paste0(
    "sha256=d96b8601b3b67fa4ed97c84ebc241e6ffbffd1a118839d2d0353bc5efa405d06 ",
    "bytes=8567 intended_two_argument_drift_write=TRUE"
  )
)

historical_path <- file.path(
  evidence_dir,
  "historical_phase4_corpus_manifest_pre.csv"
)
manifest_path <- "audit/report_harmonization/phase4_corpus_manifest.csv"
historical <- readr::read_csv(historical_path, show_col_types = FALSE)
manifest_exact <- nav_sha256_file(historical_path) ==
  unname(nav_pinned_identities[[manifest_path]]) &&
  nav_sha256_file(manifest_path) == nav_sha256_file(historical_path)
add_check(
  "historical_manifest_preimage",
  manifest_exact && nrow(historical) == 37L,
  paste0("sha256=", nav_sha256_file(manifest_path), " rows=37")
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
candidate_members <- file.path(candidate_build, promotion_manifest$path)
candidate_inventory <- nav_inventory_tree(candidate_build)
candidate_exact <- nrow(candidate_checks) == 11L &&
  all(candidate_checks$pass) &&
  nrow(promotion_manifest) == 40L &&
  !anyDuplicated(promotion_manifest$path) &&
  all(file.exists(candidate_members)) &&
  all(vapply(candidate_members, nav_sha256_file, character(1)) ==
    promotion_manifest$sha256) &&
  all(vapply(candidate_members, nav_file_bytes, numeric(1)) ==
    promotion_manifest$bytes) &&
  nrow(candidate_inventory) == 1183L &&
  sum(candidate_inventory$type == "symlink") == 0L
add_check(
  "candidate_exact",
  candidate_exact,
  "checks=11/11 members=40/40 build=1183 symlinks=0"
)

pre_build <- readr::read_csv(
  file.path(evidence_dir, "build_inventory_pre.csv"),
  show_col_types = FALSE
)
live_build <- nav_inventory_tree(file.path(project_root, "_build/nathealth"))
html_live <- vapply(historical$expected_html, nav_sha256_file, character(1))
accepted_exact <- nav_inventories_identical(pre_build, live_build) &&
  nrow(live_build) == 1180L &&
  sum(live_build$type == "file") == 871L &&
  sum(live_build$type == "directory") == 309L &&
  sum(live_build$type == "symlink") == 0L &&
  all(html_live == historical$html_sha256)
add_check(
  "accepted_html_and_build_preimages",
  accepted_exact,
  "html=37/37 build=1180/1180 files=871 directories=309 symlinks=0"
)

h09_seal_path <-
  "artifacts/12_manifests/H09/H09_stage3_observed_figure_source_seal.csv"
h09_seal <- readr::read_csv(h09_seal_path, show_col_types = FALSE)
h09_members <- file.path(project_root, h09_seal$path)
h09_exact <- nrow(h09_seal) == 24L &&
  !anyDuplicated(h09_seal$path) &&
  !h09_seal_path %in% h09_seal$path &&
  all(h09_seal$r_version == "4.6.1") &&
  all(file.exists(h09_members)) &&
  !any(dir.exists(h09_members)) &&
  !any(nzchar(Sys.readlink(h09_members))) &&
  all(vapply(h09_members, nav_sha256_file, character(1)) == h09_seal$sha256) &&
  all(vapply(h09_members, nav_file_bytes, numeric(1)) == h09_seal$bytes)
add_check(
  "h09_source_display_seal",
  h09_exact,
  "members=24/24 unique=TRUE non_circular=TRUE R=4.6.1"
)

h09_allowlist <- readr::read_csv(
  file.path(evidence_dir, "h09_concurrent_package_production_allowlist.csv"),
  show_col_types = FALSE
)
external_checkpoint_path <- file.path(
  evidence_dir,
  "navigation_external_protected_checkpoint.csv"
)
external_checkpoint <- readr::read_csv(
  external_checkpoint_path,
  show_col_types = FALSE
)
protected_pre <- readr::read_csv(
  file.path(evidence_dir, "protected_inventory_pre.csv"),
  show_col_types = FALSE
)
source_allowlist <- nav_load_authorized_source_allowlist(evidence_dir, historical)
protected_live <- nav_classify_protected_inventory(
  nav_inventory_paths(
    nav_collect_protected_paths(project_root, evidence_dir),
    project_root
  ),
  source_allowlist$path
)
added <- setdiff(protected_live$path, protected_pre$path)
removed <- setdiff(protected_pre$path, protected_live$path)
common <- intersect(protected_pre$path, protected_live$path)
changed <- common[vapply(common, function(path) {
  first <- protected_pre[protected_pre$path == path, , drop = FALSE]
  second <- protected_live[protected_live$path == path, , drop = FALSE]
  !nav_inventories_identical(first, second)
}, logical(1))]
expected_added <- h09_allowlist$path[h09_allowlist$preflight_state == "absent"]
expected_changed <- c(
  h09_allowlist$path[h09_allowlist$preflight_state == "present"],
  external_checkpoint$path
)
allowlist_live_hash <- vapply(
  h09_allowlist$path,
  nav_sha256_file,
  character(1)
)
allowlist_live_bytes <- vapply(
  h09_allowlist$path,
  nav_file_bytes,
  numeric(1)
)
external_live_hash <- vapply(
  external_checkpoint$path,
  nav_sha256_file,
  character(1)
)
external_live_bytes <- vapply(
  external_checkpoint$path,
  nav_file_bytes,
  numeric(1)
)
source_checkpoint <- nav_live_source_checkpoint(historical, project_root)
source_drift <- nav_source_drift_audit(source_checkpoint, source_allowlist)
protected_exact <- nrow(h09_allowlist) == 8L &&
  !anyDuplicated(h09_allowlist$path) &&
  nav_sha256_file(external_checkpoint_path) ==
    "7e633d5c2829ee9fad2cfa167ddb87777160cbba5e9ce8fa4b84737c100c749c" &&
  nrow(external_checkpoint) == 3L &&
  !anyDuplicated(external_checkpoint$path) &&
  !length(intersect(h09_allowlist$path, external_checkpoint$path)) &&
  setequal(added, expected_added) &&
  !length(removed) &&
  setequal(changed, expected_changed) &&
  all(allowlist_live_hash == h09_allowlist$production_sha256) &&
  all(allowlist_live_bytes == h09_allowlist$production_bytes) &&
  all(external_live_hash == external_checkpoint$checkpoint_sha256) &&
  all(external_live_bytes == external_checkpoint$checkpoint_bytes) &&
  identical(
    nav_sha256_file("notebooks/hypotheses/H09.qmd"),
    "9db9671d61b39a81fa83b234e08832cef516ee91688ac8bc4150385629648df9"
  ) &&
  nrow(source_drift) == 1L &&
  identical(source_drift$path, "notebooks/hypotheses/H09.qmd") &&
  all(source_drift$authorized)
add_check(
  "protected_delta_and_source_checkpoint",
  protected_exact,
  paste0(
    "h09_added=6 h09_changed=2 external_changed=3 ",
    "h09_qmd=9db9671d other_delta=0"
  )
)

ps_output <- system2(
  "/bin/ps",
  c("-axo", "pid=,command="),
  stdout = TRUE,
  stderr = TRUE
)
ps_status <- nav_parse_command_status(ps_output)
self_pattern <- sprintf("^\\s*%d\\s+", Sys.getpid())
# Classify processes by a build-writing or rendering purpose. An R executable
# alone is not a conflict: other workers may use R for read-only metadata,
# package, or validation probes that cannot mutate this candidate or build.
process_commands <- sub("^\\s*[0-9]+\\s+", "", ps_output, perl = TRUE)
process_pattern <- paste(
  c(
    "(^|/)(?:quarto|pandoc)(?:\\s|$)",
    "(?:quarto::)?quarto_render\\s*\\(",
    "rmarkdown::render\\s*\\(",
    "knitr::knit(?:2html)?\\s*\\(",
    "post_render_gt_html_semantics(?:\\.R)?",
    "python(?:3)?\\s+-m\\s+http\\.server",
    "build_navigation_shell_candidate(?:\\.R)?",
    "promote_navigation_candidate(?:_once)?(?:\\.R)?",
    "reseal_navigation_manifest(?:_once)?(?:\\.R)?"
  ),
  collapse = "|"
)
relevant_processes <- ps_output[
  grepl(process_pattern, process_commands, ignore.case = TRUE, perl = TRUE) &
    !grepl(self_pattern, ps_output, perl = TRUE)
]
lsof_rows <- unlist(lapply(c("55009", "56925", "57321"), function(port) {
  suppressWarnings(system2(
    "/usr/sbin/lsof",
    c("-nP", paste0("-iTCP:", port), "-sTCP:LISTEN"),
    stdout = TRUE,
    stderr = TRUE
  ))
}), use.names = FALSE)
quiet <- ps_status == 0L && !length(relevant_processes) && !length(lsof_rows)
add_check(
  "quiet_production_boundary",
  quiet,
  sprintf(
    "relevant_processes=%d loopback_listeners=%d",
    length(relevant_processes),
    length(lsof_rows)
  )
)
writeLines(
  c(
    sprintf("ps_status=%d", ps_status),
    if (length(relevant_processes)) relevant_processes else "NO_RELEVANT_PROCESS",
    if (length(lsof_rows)) lsof_rows else "NO_NAVIGATION_LOOPBACK_LISTENER"
  ),
  file.path(evidence_dir, "production_seal_process_inventory.txt"),
  useBytes = TRUE
)

checks_frame <- do.call(rbind, checks)
stopifnot(nrow(checks_frame) == 8L, all(checks_frame$pass))
readr::write_csv(checks_frame, checks_path)
readr::write_csv(
  protected_live,
  file.path(evidence_dir, "protected_inventory_production_seal.csv")
)
readr::write_csv(
  source_checkpoint,
  file.path(evidence_dir, "live_authoring_source_checkpoint_production_seal.csv")
)
readr::write_csv(
  source_drift,
  file.path(evidence_dir, "authorized_source_drift_production_seal.csv")
)

seal <- data.frame(
  execution_count = 1L,
  candidate_checks_passed = sum(candidate_checks$pass),
  candidate_checks_total = nrow(candidate_checks),
  candidate_promotion_manifest_sha256 = nav_sha256_file(promotion_manifest_path),
  candidate_build_members = nrow(candidate_inventory),
  candidate_build_symlinks = sum(candidate_inventory$type == "symlink"),
  accepted_html_exact = sum(html_live == historical$html_sha256),
  accepted_build_members = nrow(live_build),
  accepted_build_symlinks = sum(live_build$type == "symlink"),
  h09_source_seal_exact = sum(
    vapply(h09_members, nav_sha256_file, character(1)) == h09_seal$sha256
  ),
  h09_protected_package_paths = nrow(h09_allowlist),
  authorized_source_drift_paths = nrow(source_drift),
  central_concurrence_sha256 = central_hashes[[1L]],
  h09_production_allowlist_sha256 = central_hashes[[2L]],
  concurrence_manifest_sha256 = central_hashes[[3L]],
  relevant_processes = length(relevant_processes),
  loopback_listeners = length(lsof_rows),
  sealed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
readr::write_csv(seal, seal_path)

cat(
  paste0(
    "NAVIGATION_PRODUCTION_BOUNDARY=SEALED checks=8/8 candidate=40/40 ",
    "accepted_html=37/37 accepted_build=1180 h09_seal=24/24 ",
    "h09_package=8 source_drift=1 symlinks=0 processes=0 listeners=0\n"
  )
)
