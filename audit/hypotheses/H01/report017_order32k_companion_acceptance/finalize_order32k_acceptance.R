#!/usr/bin/env Rscript

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H01/report017_order32k_companion_acceptance"
)

write_csv <- function(object, filename) {
  write.csv(
    object,
    file.path(evidence_dir, filename),
    row.names = FALSE,
    na = ""
  )
}

sha <- function(path) {
  artifact_sha256(path)
}

bytes <- function(path) {
  as.numeric(file.info(path)$size)
}

required_identities <- data.frame(
  path = c(
    "audit/report_harmonization/owner_orders/32k_h01_companion_no_render_acceptance.md",
    "audit/report_harmonization/report017_h01_order32k_dispatch_manifest.csv",
    "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv",
    "audit/hypotheses/H01/H01_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html",
    "notebooks/hypotheses/H01.qmd",
    "_build/nathealth/notebooks/hypotheses/H01.html",
    "_quarto-nathealth.yml",
    "tests/hypotheses/H01/test_h01_preparation_report.R",
    "artifacts/12_manifests/H01_worker_artifacts.csv",
    file.path(
      "audit/hypotheses/H01/report017_order32k_companion_acceptance",
      "order32k_h04_global_country_findings.csv"
    )
  ),
  expected_sha256 = c(
    "4672a03ab6f5a2988e2b12b86b3d9b26e4014eb92c4979a03a3fedcb4bf5664c",
    "c7aa02097145598448819f98888e974233ea187daefb8f9c18c85030c1be9e47",
    "310a017f49992e8a4a17f8497b66112b8352364ef80526c11709c1f39155653e",
    "ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f",
    "ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f",
    "5ab6587465f01f946fcf133f9f81a69168e08fa866f69830c2378e6c3cf250fe",
    "9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb",
    "df78ac3c2ed91515058b6af38e01b85b4baae74118699c008a29ba4dacf4d007",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "7c1466cd8f964e0696c3c0a17fc2c53a9702dd7ccbb84e0e4926089b56de0fc6",
    "d695d40401f3d6758fa81a8370d7bd224c3526a8038258e835e5917c8f675bb6",
    "cc7d51ae2248b9223250580f12b48bc6092d10eb9b22e85a6682ee923f31f963"
  ),
  stringsAsFactors = FALSE
)
required_identities$current_sha256 <- vapply(
  required_identities$path,
  sha,
  character(1)
)
required_identities$current_bytes <- vapply(
  required_identities$path,
  bytes,
  numeric(1)
)
required_identities$status <- ifelse(
  required_identities$current_sha256 == required_identities$expected_sha256,
  "PASS",
  "FAIL"
)
stopifnot(all(required_identities$status == "PASS"))
write_csv(required_identities, "order32k_final_identity_audit.csv")

preparation_manifest <- read.csv(
  "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
preparation_manifest$current_sha256 <- vapply(
  preparation_manifest$path,
  sha,
  character(1)
)
preparation_manifest$current_bytes <- vapply(
  preparation_manifest$path,
  bytes,
  numeric(1)
)
preparation_manifest$live_exact <-
  preparation_manifest$sha256 == preparation_manifest$current_sha256 &
  preparation_manifest$bytes == preparation_manifest$current_bytes
stopifnot(
  nrow(preparation_manifest) == 65L,
  !anyDuplicated(preparation_manifest$path),
  all(preparation_manifest$live_exact)
)

worker_audit <- read.csv(
  file.path(evidence_dir, "order32k_worker_manifest_audit_post.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
worker_rows <- read.csv(
  file.path(evidence_dir, "order32k_worker_five_row_reseal.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
worker_reverse <- read.csv(
  file.path(evidence_dir, "order32k_worker_reverse_proof.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(worker_audit) == 1659L,
  sum(worker_audit$status == "PASS_LIVE_EXACT") == 1657L,
  sum(worker_audit$status == "ACCEPTED_HISTORICAL_TRANSITION") == 2L,
  nrow(worker_rows) == 5L,
  all(worker_rows$status == "PASS"),
  nrow(worker_reverse) == 4L,
  worker_reverse$sha256[worker_reverse$item == "pre_worker"] ==
    worker_reverse$sha256[
      worker_reverse$item == "reverse_reconstruction"
    ],
  worker_reverse$classification[
    worker_reverse$item == "reverse_reconstruction"
  ] == "EXACT_REVERSE_TO_PREIMAGE"
)

test_results <- read.csv(
  file.path(evidence_dir, "order32k_test_results.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
html_contracts <- read.csv(
  file.path(evidence_dir, "order32k_html_contracts.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
tables <- read.csv(
  file.path(evidence_dir, "order32k_table_endpoint_audit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
figures <- read.csv(
  file.path(evidence_dir, "order32k_figure_endpoint_audit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
headers <- read.csv(
  file.path(evidence_dir, "order32k_header_resolution_audit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
idrefs <- read.csv(
  file.path(evidence_dir, "order32k_idref_resolution_audit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
h04_findings <- read.csv(
  file.path(evidence_dir, "order32k_h04_global_country_findings.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(test_results) == 7L,
  all(test_results$contract_status == "PASS"),
  all(html_contracts$pass),
  nrow(tables) == 20L,
  nrow(figures) == 2L,
  nrow(headers) == 1442L,
  all(headers$pass),
  nrow(idrefs) == 1471L,
  all(idrefs$pass),
  nrow(h04_findings) == 2L,
  identical(h04_findings$path, c(
    "notebooks/hypotheses/H04.qmd",
    "audit/hypotheses/H04/H04_analysis_preparation.qmd"
  )),
  identical(h04_findings$line, c(886L, 914L))
)

build_reconciliation <- read.csv(
  file.path(evidence_dir, "order32k_build_reconciliation_postedit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
protected_reconciliation <- read.csv(
  file.path(evidence_dir, "order32k_protected_reconciliation_postedit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(build_reconciliation) == 1118L,
  all(build_reconciliation$content_identical),
  nrow(protected_reconciliation) == 1725L,
  !any(protected_reconciliation$classification == "FAIL_UNEXPECTED_DRIFT"),
  sum(
    protected_reconciliation$classification ==
      "EXTERNAL_ORDER35B_POST_FINDING_TRANSITION"
  ) == 2L
)

h04_live <- data.frame(
  path = c(
    "notebooks/hypotheses/H04.qmd",
    "audit/hypotheses/H04/H04_analysis_preparation.qmd",
    "audit/handoffs/H04_worker_handoff.md"
  ),
  checkpoint_sha256 = c(
    "63e815683e1e81dadd480aeb230c7913de7726aa9242f5ce89ec4a0e7e90471c",
    "52160297aaaa65f9cc0e36839adb0fcbe86e55631c847476b5006f03d657e9da",
    "1961b349d527b3c945d0d299a27f46603a674843629a918461ea2a504023b50a"
  ),
  current_sha256 = c(
    "f8adb6d78be041ce296dd7e89eb92769b128631c1b4227ce5d8ab3d526daf1d5",
    "efdb5be8dc194695f40c50249fab14905ec337bc63079ae589557de860188474",
    "99de6fd036b7e7c52a55406615642024092e3177317255101c4a5db1ff391036"
  ),
  current_bytes = c(83285, 91202, 31926),
  classification = "EXTERNAL_CONCURRENT_ORDER35B",
  stringsAsFactors = FALSE
)
h04_live$observed_sha256 <- vapply(h04_live$path, sha, character(1))
h04_live$observed_bytes <- vapply(h04_live$path, bytes, numeric(1))
h04_live$status <- ifelse(
  h04_live$observed_sha256 == h04_live$current_sha256 &
    h04_live$observed_bytes == h04_live$current_bytes,
  "PASS_EXTERNAL_CLASSIFICATION",
  "FAIL"
)
stopifnot(all(h04_live$status == "PASS_EXTERNAL_CLASSIFICATION"))

h04_authorization <- data.frame(
  path = c(
    "audit/report_harmonization/owner_orders/35b_h04_country_label_source_reflow.md",
    "audit/report_harmonization/report017_h04_order35b_dispatch_manifest.csv"
  ),
  expected_sha256 = c(
    "eef9e794836a06d1d92d8cac10f8dbe9cbe6023afc444e3deabeac291c9253c3",
    "335d304a5886a6876685ed4cee93536a99859cfeec9cf066c96608e02a213b09"
  ),
  stringsAsFactors = FALSE
)
h04_authorization$observed_sha256 <- vapply(
  h04_authorization$path,
  sha,
  character(1)
)
h04_authorization$observed_bytes <- vapply(
  h04_authorization$path,
  bytes,
  numeric(1)
)
h04_authorization$status <- ifelse(
  h04_authorization$expected_sha256 == h04_authorization$observed_sha256,
  "PASS",
  "FAIL"
)
stopifnot(all(h04_authorization$status == "PASS"))

h04_manifest_path <- paste0(
  "audit/hypotheses/H04/report017_order35b_country_label_reflow/",
  "H04_order35b_non_circular_owner_manifest.csv"
)
h04_manifest <- read.csv(
  h04_manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
h04_manifest$observed_sha256 <- vapply(h04_manifest$path, sha, character(1))
h04_manifest$observed_bytes <- vapply(h04_manifest$path, bytes, numeric(1))
h04_manifest$live_exact <-
  h04_manifest$sha256 == h04_manifest$observed_sha256 &
  h04_manifest$bytes == h04_manifest$observed_bytes
h04_manifest$status <- ifelse(
  h04_manifest$live_exact,
  "PASS_LIVE_EXACT",
  ifelse(
    h04_manifest$path ==
      "audit/report_harmonization/coordination_matrix.csv",
    "ALLOWED_MUTABLE_COORDINATION_EVIDENCE",
    "FAIL"
  )
)
stopifnot(
  sha(h04_manifest_path) ==
    "76bdf811aff2d38326b5c1cc1a27e0cf8d0cca1aa8c73d4638c1917b9e829b54",
  nrow(h04_manifest) == 24L,
  !anyDuplicated(h04_manifest$path),
  !any(h04_manifest$path == h04_manifest_path),
  !any(h04_manifest$status == "FAIL"),
  identical(
    h04_manifest$path[
      h04_manifest$status == "ALLOWED_MUTABLE_COORDINATION_EVIDENCE"
    ],
    "audit/report_harmonization/coordination_matrix.csv"
  )
)
write_csv(h04_live, "order32k_external_order35b_classification.csv")
write_csv(
  h04_authorization,
  "order32k_external_order35b_authorization.csv"
)
write_csv(
  h04_manifest,
  "order32k_external_order35b_manifest_audit.csv"
)

screenshot_paths <- list.files(
  evidence_dir,
  pattern = "[.]png$",
  full.names = TRUE
)
screenshot_manifest <- data.frame(
  path = file.path(
    "audit/hypotheses/H01/report017_order32k_companion_acceptance",
    basename(screenshot_paths)
  ),
  sha256 = vapply(screenshot_paths, sha, character(1)),
  bytes = vapply(screenshot_paths, bytes, numeric(1)),
  stringsAsFactors = FALSE
)
stopifnot(nrow(screenshot_manifest) == 17L)
write_csv(screenshot_manifest, "order32k_screenshot_manifest.csv")

server_lifecycle <- data.frame(
  field = c(
    "command",
    "pid",
    "bind_address",
    "port",
    "document_root",
    "start_time_utc",
    "url",
    "teardown_signal",
    "teardown_verification_time_utc",
    "process_after_teardown",
    "listener_after_teardown"
  ),
  value = c(
    "python3 -m http.server 0 --bind 127.0.0.1",
    "48904",
    "127.0.0.1",
    "62390",
    file.path(root, "_build/nathealth"),
    "2026-08-20T07:53:53Z",
    paste0(
      "http://127.0.0.1:62390/audit/hypotheses/H01/",
      "H01_analysis_preparation.html"
    ),
    "SIGINT delivered through the owning terminal session",
    "2026-08-20T08:09:00Z",
    "none",
    "none"
  ),
  stringsAsFactors = FALSE
)
write_csv(server_lifecycle, "order32k_loopback_server_lifecycle.csv")

visual_assessment <- data.frame(
  check = c(
    "desktop_1440x1000",
    "narrow_708x1000",
    "detailed_200_percent_equivalent",
    "native_gt_tables",
    "sample_tabset",
    "horizontal_scroller",
    "figures_final_display",
    "figures_original_size",
    "mermaid",
    "callouts_and_headings",
    "links_and_navigation",
    "browser_console",
    "page_overflow"
  ),
  evidence = c(
    "Full-page and focused screenshots; no clipping, overlap, or distorted text",
    "Full-page and focused screenshots; document width 693 equals scroll width 693",
    "720 by 500 CSS viewport gives the 1440 by 1000 screen's 200 percent content geometry",
    "20 endpoints retained; 19 visible plus one inactive tab panel; 12 px table text",
    "Near-eye and chest tables both inspected and readable",
    "Table 18 moved from scrollLeft 0 to 75 of 75; table 19 has the same contained geometry",
    "Both figures fit within the reader column and retain readable labels and legends",
    "Both 2016 by 1497 PNGs inspected directly",
    "Top-to-bottom dependency map is complete, bounded, and readable",
    "Hierarchy, notes, captions, and explanatory text are visible and unobstructed",
    "Active companion navigation, reciprocal result links, and two source-data links resolve structurally",
    "No warning or error entries",
    "No document-level horizontal overflow at desktop, narrow, or detailed geometry"
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
write_csv(visual_assessment, "order32k_visual_acceptance.csv")

commands <- data.frame(
  stage = c(
    "preflight",
    "test_repair",
    "worker_reseal",
    "no_render_checks",
    "semantic_audit",
    "postedit_reconciliation",
    "loopback_server",
    "browser_qa",
    "teardown",
    "final_seal"
  ),
  command = c(
    "Rscript --vanilla collect_order32k_preflight.R",
    "Rscript --vanilla record_order32k_test_repair.R",
    "Rscript --vanilla complete_order32k_worker_reseal.R",
    "Rscript --vanilla run_order32k_checks.R",
    "Rscript --vanilla run_order32k_semantic_audit.R",
    "Rscript --vanilla audit_order32k_postedit_state.R",
    "python3 -m http.server 0 --bind 127.0.0.1",
    "Codex in-app browser against the isolated 127.0.0.1 URL",
    "SIGINT; read-only ps and lsof verification",
    "Rscript --vanilla finalize_order32k_acceptance.R"
  ),
  scientific_execution = FALSE,
  quarto_command = FALSE,
  stringsAsFactors = FALSE
)
write_csv(commands, "order32k_command_record.csv")

git_diff_check <- system2(
  "git",
  c(
    "diff",
    "--check",
    "--",
    "tests/hypotheses/H01/test_h01_preparation_report.R",
    "artifacts/12_manifests/H01_worker_artifacts.csv"
  ),
  stdout = TRUE,
  stderr = TRUE
)
stopifnot(length(git_diff_check) == 0L)
writeLines("PASS", file.path(evidence_dir, "order32k_git_diff_check.txt"))

acceptance_lines <- c(
  "# REPORT-017 H01 order 32k companion no-render acceptance",
  "",
  "Status: PASS",
  "",
  "The existing H01 preparation and provenance HTML is accepted without a Quarto command or scientific execution.",
  "",
  "- The preparation manifest is byte-identical and 65 of 65 rows are live-exact.",
  "- The one stale test literal was replaced with `17-response package`; its exact reverse proof passes.",
  "- Exactly five worker-manifest rows were resealed. The manifest is 1,657 of 1,659 live-exact, with only the two accepted historical result-HTML and profile rows remaining.",
  "- All seven no-render test contracts pass. Six ordinary tests pass directly, and the global country test produced exactly the two H04 findings durably recorded before H04 order 35b began.",
  "- The companion retains 20 native gt tables, two figures, 1,442 resolving header tokens, 1,471 resolving supported ID references, nine country-coded sites, active navigation, reciprocal links, and two source-data downloads.",
  "- Desktop, 708-pixel, detailed 200-percent-equivalent, original-figure, tabset, horizontal-scroller, Mermaid, callout, caption, and full-page visual checks pass.",
  "- The loopback server was bound only to 127.0.0.1, then stopped. No process or listener remained.",
  "- The complete 1,118-path build inventory is unchanged and contains no symlink.",
  "- The only post-checkpoint external transitions are the separately sealed H04 order-35b country-label reflows and H04 handoff append. They are not H01 mutations.",
  "- H01 QMDs, accepted HTML, profile, preparation helper, scientific artifacts, and all other protected paths remain unchanged.",
  ""
)
writeLines(
  acceptance_lines,
  file.path(evidence_dir, "order32k_acceptance_record.md")
)

manifest_path <- file.path(
  evidence_dir,
  "order32k_non_circular_completion_manifest.csv"
)
evidence_files <- list.files(
  evidence_dir,
  full.names = TRUE,
  recursive = FALSE
)
evidence_files <- evidence_files[
  !dir.exists(evidence_files) & normalizePath(
    evidence_files,
    winslash = "/",
    mustWork = TRUE
  ) != normalizePath(
    manifest_path,
    winslash = "/",
    mustWork = FALSE
  )
]
completion_manifest <- data.frame(
  path = file.path(
    "audit/hypotheses/H01/report017_order32k_companion_acceptance",
    basename(evidence_files)
  ),
  role = ifelse(
    grepl("[.]png$", evidence_files),
    "loopback_visual_qa_screenshot",
    ifelse(
      grepl("[.]R$", evidence_files),
      "bounded_owner_evidence_script",
      "bounded_owner_evidence"
    )
  ),
  sha256 = vapply(evidence_files, sha, character(1)),
  bytes = vapply(evidence_files, bytes, numeric(1)),
  stringsAsFactors = FALSE
)
completion_manifest <- completion_manifest[
  order(completion_manifest$path),
  ,
  drop = FALSE
]
stopifnot(
  !anyDuplicated(completion_manifest$path),
  !any(completion_manifest$path == file.path(
    "audit/hypotheses/H01/report017_order32k_companion_acceptance",
    basename(manifest_path)
  ))
)
write.csv(completion_manifest, manifest_path, row.names = FALSE, na = "")

cat(sprintf(
  paste0(
    "order32k=PASS preparation=65/65 worker=1657/1659 tests=7/7 ",
    "tables=20 figures=2 headers=1442 idrefs=1471 screenshots=%d ",
    "build=1118/1118 evidence=%d\n"
  ),
  nrow(screenshot_manifest),
  nrow(completion_manifest)
))
