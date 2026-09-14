#!/usr/bin/env Rscript

stopifnot(identical(as.character(getRversion()), "4.6.1"))
root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))

evidence_relative <-
  "audit/hypotheses/H01/report017_order32i_preparation_render"
evidence_dir <- file.path(root, evidence_relative)
semantic_dir <- "/private/tmp/H01-order32i-semantics.Or8lWE"
stopifnot(dir.exists(evidence_dir), dir.exists(semantic_dir))

write_csv <- function(object, filename) {
  utils::write.csv(
    object,
    file.path(evidence_dir, filename),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

post_build <- utils::read.csv(
  file.path(evidence_dir, "order32i_build_inventory_post.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
postqa_build <- utils::read.csv(
  file.path(evidence_dir, "order32i_build_inventory_postqa.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
post_protected <- utils::read.csv(
  file.path(evidence_dir, "order32i_protected_inventory_post.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
postqa_protected <- utils::read.csv(
  file.path(evidence_dir, "order32i_protected_inventory_postqa.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

postqa_reconciliation <- data.frame(
  inventory = c("build", "protected"),
  rows_post = c(nrow(post_build), nrow(post_protected)),
  rows_postqa = c(nrow(postqa_build), nrow(postqa_protected)),
  exact_all_fields = c(
    identical(post_build, postqa_build),
    identical(post_protected, postqa_protected)
  ),
  stringsAsFactors = FALSE
)
stopifnot(all(postqa_reconciliation$exact_all_fields))
write_csv(postqa_reconciliation, "order32i_post_to_postqa_reconciliation.csv")

semantic_files <- sort(list.files(
  semantic_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
))
stopifnot(length(semantic_files) == 2L, all(file.exists(semantic_files)))
semantic_manifest <- data.frame(
  absolute_path = semantic_files,
  sha256 = vapply(semantic_files, artifact_sha256, character(1)),
  bytes = as.numeric(file.info(semantic_files)$size),
  role = ifelse(
    grepl("summary[.]csv$", semantic_files),
    "semantic_summary",
    "reversible_semantic_ledger"
  ),
  stringsAsFactors = FALSE
)
write_csv(semantic_manifest, "order32i_external_semantic_manifest.csv")

timeline <- data.frame(
  event = c(
    "pre_inventory_complete",
    "render_started",
    "rendered_html_created",
    "semantic_hook_complete",
    "focused_test_complete",
    "postqa_inventory_complete"
  ),
  timestamp_utc = c(
    "2026-08-20T06:48:49.187978Z",
    "not directly captured; after immediate 13/13 preflight",
    "2026-08-20T06:50:14Z",
    "2026-08-20T06:50:56Z",
    "2026-08-20T06:52:56.401566Z",
    "2026-08-20T06:59:34.377985Z"
  ),
  evidence = c(
    "order32i_inventory_summary_pre.csv",
    "single exec invocation; approximately 65 seconds total",
    "target HTML birth time",
    "semantic summary and target HTML mtime",
    "order32i_focused_test_summary.csv",
    "order32i_inventory_summary_postqa.csv"
  ),
  stringsAsFactors = FALSE
)
write_csv(timeline, "order32i_execution_timeline.csv")

render_execution <- data.frame(
  command = paste0(
    "GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H01-order32i-semantics.Or8lWE ",
    "quarto render audit/hypotheses/H01/H01_analysis_preparation.qmd ",
    "--profile nathealth"
  ),
  invocations = 1L,
  exit_status = 0L,
  elapsed_seconds_approximate = 65.0,
  quarto_version = "1.9.37",
  r_version = "4.6.1",
  semantic_disposition = "REPAIRED",
  output_html_sha256 = artifact_sha256(
    "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html"
  ),
  stringsAsFactors = FALSE
)
write_csv(render_execution, "order32i_render_execution.csv")

loopback <- data.frame(
  status = "NOT_STARTED_NONVISUAL_GATE_FAILED",
  server_started = FALSE,
  bind_address = NA_character_,
  port = NA_integer_,
  target_url = NA_character_,
  screenshots = 0L,
  listener_remaining = FALSE,
  reason = paste0(
    "Order 32i permits loopback only after all nonvisual checks pass; ",
    "two source-data links and the complete preparation test failed."
  ),
  stringsAsFactors = FALSE
)
write_csv(loopback, "order32i_loopback_lifecycle.csv")

key_paths <- c(
  "audit/report_harmonization/owner_orders/32i_h01_preparation_provenance_target_render.md",
  "audit/report_harmonization/report017_h01_order32i_dispatch_manifest.csv",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html",
  "notebooks/hypotheses/H01.qmd",
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "_quarto-nathealth.yml",
  "tests/hypotheses/H01/test_h01_preparation_report.R",
  "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv",
  "audit/handoffs/H01_worker_handoff.md",
  "scripts/report_harmonization/post_render_gt_html_semantics.R",
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  "artifacts/11_source_data/H01/preparation/H01_preparation_fitted_sample_support.csv",
  "artifacts/11_source_data/H01/preparation/H01_preparation_model_frame_retention.csv"
)
stopifnot(all(file.exists(key_paths)), all(!dir.exists(key_paths)))
key_identities <- data.frame(
  path = key_paths,
  sha256 = vapply(key_paths, artifact_sha256, character(1)),
  bytes = as.numeric(file.info(key_paths)$size),
  stringsAsFactors = FALSE
)
write_csv(key_identities, "order32i_final_key_identities.csv")

git_output <- system2(
  "git",
  c(
    "status",
    "--short",
    "--",
    evidence_relative,
    "audit/hypotheses/H01/H01_analysis_preparation.qmd",
    "notebooks/hypotheses/H01.qmd",
    "_quarto-nathealth.yml",
    "tests/hypotheses/H01/test_h01_preparation_report.R",
    "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv",
    "audit/handoffs/H01_worker_handoff.md",
    "scripts/report_harmonization/post_render_gt_html_semantics.R",
    "scripts/report_harmonization/repair_gt_html_semantics.R"
  ),
  stdout = TRUE,
  stderr = TRUE
)
writeLines(
  enc2utf8(git_output),
  file.path(evidence_dir, "order32i_scoped_git_status.txt"),
  useBytes = TRUE
)

manifest_path <- file.path(evidence_dir, "order32i_owner_evidence_manifest.csv")
evidence_files <- sort(list.files(
  evidence_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
))
evidence_files <- evidence_files[file.exists(evidence_files) &
  !dir.exists(evidence_files)]
evidence_files <- setdiff(evidence_files, manifest_path)
owner_manifest <- data.frame(
  path = substring(evidence_files, nchar(root) + 2L),
  sha256 = vapply(evidence_files, artifact_sha256, character(1)),
  bytes = as.numeric(file.info(evidence_files)$size),
  role = ifelse(
    grepl("[.]R$", evidence_files),
    "owner_evidence_code",
    ifelse(
      grepl("stopped_state[.]md$", evidence_files),
      "stopped_state_handoff",
      "owner_evidence"
    )
  ),
  stringsAsFactors = FALSE
)
stopifnot(!any(owner_manifest$path == substring(
  manifest_path,
  nchar(root) + 2L
)))
write_csv(owner_manifest, basename(manifest_path))

cat(sprintf(
  paste0(
    "seal=PASS postqa_build=%d postqa_protected=%d semantic_files=%d ",
    "owner_manifest_rows=%d output_html=%s\n"
  ),
  nrow(postqa_build),
  nrow(postqa_protected),
  nrow(semantic_manifest),
  nrow(owner_manifest),
  render_execution$output_html_sha256
))
