#!/usr/bin/env Rscript

# Read-only preflight for the bounded no-rerender navigation integration.

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
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)
evidence_dir <- normalizePath(evidence_dir, winslash = "/", mustWork = TRUE)

checks <- list()
add_check <- function(check_id, pass, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check_id = check_id,
    pass = isTRUE(pass),
    detail = as.character(detail),
    stringsAsFactors = FALSE
  )
}

pinned_paths <- file.path(project_root, names(nav_pinned_identities))
pinned <- data.frame(
  path = names(nav_pinned_identities),
  expected_sha256 = unname(nav_pinned_identities),
  live_sha256 = vapply(pinned_paths, nav_sha256_file, character(1)),
  bytes = vapply(pinned_paths, nav_file_bytes, numeric(1)),
  stringsAsFactors = FALSE
)
pinned$exact <- pinned$expected_sha256 == pinned$live_sha256
readr::write_csv(pinned, file.path(evidence_dir, "pinned_identities_pre.csv"))
add_check(
  "pinned_inputs",
  nrow(pinned) == 5L && all(pinned$exact),
  sprintf("exact=%d/%d", sum(pinned$exact), nrow(pinned))
)

manifest_path <- file.path(
  project_root,
  "audit/report_harmonization/phase4_corpus_manifest.csv"
)
historical_path <- file.path(
  evidence_dir,
  "historical_phase4_corpus_manifest_pre.csv"
)
if (!file.exists(historical_path)) {
  nav_copy_file_exact(manifest_path, historical_path)
}
historical_exact <-
  nav_sha256_file(historical_path) == unname(nav_pinned_identities[[
    "audit/report_harmonization/phase4_corpus_manifest.csv"
  ]]) &&
  nav_sha256_file(historical_path) == nav_sha256_file(manifest_path)
add_check(
  "historical_manifest_copy",
  historical_exact,
  paste0("sha256=", nav_sha256_file(historical_path))
)

manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
source_paths <- file.path(project_root, manifest$source)
html_paths <- file.path(project_root, manifest$expected_html)
accepted_source_baseline <- data.frame(
  logical_order = manifest$logical_order,
  path = manifest$source,
  role = manifest$role,
  accepted_source_sha256 = manifest$source_sha256,
  stringsAsFactors = FALSE
)
readr::write_csv(
  accepted_source_baseline,
  file.path(evidence_dir, "accepted_source_baseline.csv")
)
allowlist <- nav_load_authorized_source_allowlist(evidence_dir, manifest)
live_source_checkpoint <- nav_live_source_checkpoint(manifest, project_root)
readr::write_csv(
  live_source_checkpoint,
  file.path(evidence_dir, "live_authoring_source_checkpoint_preflight.csv")
)
source_drift <- nav_source_drift_audit(live_source_checkpoint, allowlist)
readr::write_csv(
  source_drift,
  file.path(evidence_dir, "authorized_source_drift_preflight.csv")
)
corpus <- data.frame(
  logical_order = manifest$logical_order,
  source = manifest$source,
  expected_html = manifest$expected_html,
  source_sha256 = manifest$source_sha256,
  live_source_sha256 = vapply(source_paths, nav_sha256_file, character(1)),
  html_sha256 = manifest$html_sha256,
  live_html_sha256 = vapply(html_paths, nav_sha256_file, character(1)),
  stringsAsFactors = FALSE
)
corpus$source_exact <- corpus$source_sha256 == corpus$live_source_sha256
corpus$html_exact <- corpus$html_sha256 == corpus$live_html_sha256
readr::write_csv(corpus, file.path(evidence_dir, "corpus_live_pre.csv"))
add_check(
  "accepted_html_and_authoring_source_classification",
  nrow(corpus) == 37L &&
    all(corpus$html_exact) &&
    !anyDuplicated(corpus$source) &&
    !anyDuplicated(corpus$expected_html) &&
    all(file.exists(source_paths)) &&
    all(source_drift$authorized) &&
    all(source_drift$path %in% allowlist$path),
  sprintf(
    "accepted_source_matches=%d/37 authorized_source_drift=%d html=%d/37",
    sum(corpus$source_exact),
    nrow(source_drift),
    sum(corpus$html_exact)
  )
)

source_inventory <- nav_inventory_paths(source_paths, project_root)
source_inventory <- nav_classify_protected_inventory(
  source_inventory,
  allowlist$path
)
readr::write_csv(
  source_inventory,
  file.path(evidence_dir, "source_inventory_pre.csv")
)

build_inventory <- nav_inventory_tree(file.path(project_root, "_build/nathealth"))
build_routes <- vapply(manifest$expected_html, nav_html_route, character(1))
build_inventory$navigation_classification <- ifelse(
  build_inventory$path %in% build_routes,
  "NAVIGATION_PROMOTION_EXPECTED",
  "NAVIGATION_FIXED_EXACT"
)
readr::write_csv(
  build_inventory,
  file.path(evidence_dir, "build_inventory_pre.csv")
)
add_check(
  "accepted_build_inventory",
  nrow(build_inventory) == 1180L &&
    sum(build_inventory$type == "file") == 871L &&
    sum(build_inventory$type == "directory") == 309L &&
    sum(build_inventory$type == "symlink") == 0L,
  sprintf(
    "members=%d files=%d directories=%d symlinks=%d",
    nrow(build_inventory),
    sum(build_inventory$type == "file"),
    sum(build_inventory$type == "directory"),
    sum(build_inventory$type == "symlink")
  )
)

protected_paths <- nav_collect_protected_paths(project_root, evidence_dir)
protected_inventory <- nav_inventory_paths(protected_paths, project_root)
protected_inventory <- nav_classify_protected_inventory(
  protected_inventory,
  allowlist$path
)
readr::write_csv(
  protected_inventory,
  file.path(evidence_dir, "protected_inventory_pre.csv")
)
add_check(
  "protected_inventory",
  nrow(protected_inventory) > 3000L &&
    sum(protected_inventory$type == "symlink") == 0L,
  sprintf("members=%d symlinks=%d", nrow(protected_inventory), 0L)
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
  "post_render_gt_html_semantics|python(?:3)?\\s+-m\\s+http\\.server"
)
relevant_processes <- ps_output[
  grepl(process_pattern, ps_output, ignore.case = TRUE, perl = TRUE) &
    !grepl(self_pattern, ps_output, perl = TRUE)
]
writeLines(
  c(
    sprintf("ps_status=%d", ps_status),
    if (length(relevant_processes)) relevant_processes else "NO_RELEVANT_PROCESS"
  ),
  file.path(evidence_dir, "process_inventory_pre.txt"),
  useBytes = TRUE
)

lsof_output <- suppressWarnings(system2(
  "/usr/sbin/lsof",
  c("-nP", "-iTCP:55009", "-sTCP:LISTEN"),
  stdout = TRUE,
  stderr = TRUE
))
lsof_status <- nav_parse_command_status(lsof_output)
writeLines(
  c(
    sprintf("lsof_status=%d", lsof_status),
    if (length(lsof_output)) lsof_output else "NO_LISTENER_55009"
  ),
  file.path(evidence_dir, "preview_listener_pre.txt"),
  useBytes = TRUE
)
add_check(
  "quiet_serial_environment",
  ps_status == 0L && length(relevant_processes) == 0L &&
    lsof_status != 0L && length(lsof_output) == 0L,
  sprintf(
    "relevant_processes=%d preview_listener=%d",
    length(relevant_processes),
    length(lsof_output)
  )
)

rscript <- file.path(R.home("bin"), "Rscript")
reader_output <- suppressWarnings(system2(
  rscript,
  c("--vanilla", "tests/report_harmonization/test_reader_links.R"),
  stdout = TRUE,
  stderr = TRUE,
  env = c("RENV_CONFIG_AUTOLOADER_ENABLED=FALSE")
))
reader_status <- nav_parse_command_status(reader_output)
writeLines(
  enc2utf8(reader_output),
  file.path(evidence_dir, "reader_links_pre.txt"),
  useBytes = TRUE
)
reader_text <- paste(reader_output, collapse = "\n")
reader_pass <- reader_status == 0L &&
  grepl("passed for 37 QMD sources", reader_text, fixed = TRUE) &&
  grepl("anchors: 86", reader_text, fixed = TRUE)
add_check(
  "reader_link_contract",
  reader_pass,
  sprintf("status=%d sources=37 anchors=86", reader_status)
)

checks_frame <- do.call(rbind, checks)
readr::write_csv(checks_frame, file.path(evidence_dir, "preflight_checks.csv"))
stopifnot(nrow(checks_frame) == 7L, all(checks_frame$pass))

summary <- data.frame(
  phase = "preflight",
  manifest_sha256 = nav_sha256_file(manifest_path),
  sources_exact = sum(corpus$source_exact),
  authorized_source_drift = nrow(source_drift),
  html_exact = sum(corpus$html_exact),
  build_members = nrow(build_inventory),
  build_files = sum(build_inventory$type == "file"),
  build_directories = sum(build_inventory$type == "directory"),
  build_symlinks = sum(build_inventory$type == "symlink"),
  protected_members = nrow(protected_inventory),
  checks_passed = sum(checks_frame$pass),
  checks_total = nrow(checks_frame),
  R_version = as.character(getRversion()),
  stringsAsFactors = FALSE
)
readr::write_csv(summary, file.path(evidence_dir, "preflight_summary.csv"))

cat(sprintf(
  paste0(
    "NAVIGATION_INTEGRATION_PREFLIGHT=PASS checks=%d/%d ",
    "accepted_source_baseline=37 live_source_matches=%d ",
    "authorized_source_drift=%d html=37/37 build=1180 files=871 ",
    "directories=309 symlinks=0 anchors=86 R=%s\n"
  ),
  sum(checks_frame$pass),
  nrow(checks_frame),
  sum(corpus$source_exact),
  nrow(source_drift),
  as.character(getRversion())
))
