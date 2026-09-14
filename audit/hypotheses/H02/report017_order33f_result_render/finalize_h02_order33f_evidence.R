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
  "audit/hypotheses/H02/report017_order33f_result_render"
)

read_evidence <- function(filename) {
  utils::read.csv(
    file.path(evidence_dir, filename),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

write_evidence <- function(object, filename) {
  utils::write.csv(
    object,
    file.path(evidence_dir, filename),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

collapse_paths <- function(paths) paste(sort(paths), collapse = " | ")

# Complete accepted-path reconciliation.
accepted_pre <- read_evidence("accepted_inventory_prerender.csv")
accepted_post <- read_evidence("accepted_inventory_postrender.csv")
accepted <- merge(
  accepted_pre,
  accepted_post,
  by = c("path", "classification"),
  all = TRUE,
  suffixes = c("_pre", "_post"),
  sort = TRUE
)
accepted$byte_exact <- with(
  accepted,
  exists_pre & exists_post &
    type_pre == type_post &
    sha256_pre == sha256_post &
    bytes_pre == bytes_post
)
accepted$allowed <- with(
  accepted,
  ifelse(classification == "target_html", TRUE, byte_exact)
)
accepted$disposition <- with(
  accepted,
  ifelse(
    classification == "target_html" & !byte_exact,
    "expected_target_render_change",
    ifelse(byte_exact, "byte_identical", "unexpected_change")
  )
)
write_evidence(accepted, "accepted_reconciliation_postrender.csv")

protected <- accepted[accepted$classification == "protected", ]
protected_summary <- data.frame(
  inventory = "accepted protected paths",
  rows = nrow(protected),
  byte_identical = sum(protected$byte_exact),
  changed = sum(!protected$byte_exact),
  pass = nrow(protected) == 210L && all(protected$byte_exact),
  stringsAsFactors = FALSE
)
write_evidence(protected_summary, "protected_reconciliation_summary.csv")

# Complete scoped build delta and classification.
build_pre <- read_evidence("build_inventory_prerender.csv")
build_post <- read_evidence("build_inventory_postrender.csv")
build <- merge(
  build_pre,
  build_post,
  by = "path",
  all = TRUE,
  suffixes = c("_pre", "_post"),
  sort = TRUE
)

is_na_pre <- is.na(build$type_pre)
is_na_post <- is.na(build$type_post)
same_type <- !is_na_pre & !is_na_post & build$type_pre == build$type_post
same_content <- same_type & ifelse(
  build$type_pre == "file",
  build$sha256_pre == build$sha256_post & build$bytes_pre == build$bytes_post,
  TRUE
)
same_mtime <- same_type & build$mtime_utc_pre == build$mtime_utc_post

build$change_type <- ifelse(
  is_na_pre & !is_na_post,
  "added",
  ifelse(
    !is_na_pre & is_na_post,
    "removed",
    ifelse(
      !same_type,
      "type_changed",
      ifelse(!same_content, "content_changed", ifelse(!same_mtime, "mtime_only", "unchanged"))
    )
  )
)

delta <- build[build$change_type != "unchanged", ]
delta$source_path <- NA_character_
delta$source_identical <- NA
delta$classification <- "unclassified"
delta$allowed <- FALSE

directory_rows <- delta$type_post == "directory" &
  delta$change_type %in% c("added", "mtime_only")
delta$classification[directory_rows] <- ifelse(
  delta$change_type[directory_rows] == "added",
  "target_render_created_directory",
  "directory_mtime_touch"
)
delta$allowed[directory_rows] <- TRUE

copied_resources <- c(
  "artifacts/09_tables/H02/dominance_summary.csv",
  "artifacts/09_tables/H02/variation_summary.csv",
  "artifacts/11_source_data/H02/paired_placement_site_curves.csv",
  "artifacts/11_source_data/H02/site_curve_predictions.csv"
)
copy_rows <- delta$path %in% copied_resources & delta$change_type == "added"
delta$source_path[copy_rows] <- delta$path[copy_rows]
delta$source_identical[copy_rows] <- vapply(
  seq_len(sum(copy_rows)),
  function(index) {
    row_index <- which(copy_rows)[[index]]
    source_path <- file.path(root, delta$source_path[[row_index]])
    file.exists(source_path) &&
      artifact_sha256(source_path) == delta$sha256_post[[row_index]] &&
      as.numeric(file.info(source_path)$size) == delta$bytes_post[[row_index]]
  },
  logical(1)
)
delta$classification[copy_rows] <- "source_identical_target_resource_copy"
delta$allowed[copy_rows] <- delta$source_identical[copy_rows]

target_html_row <- delta$path == "notebooks/hypotheses/H02.html" &
  delta$change_type == "content_changed"
delta$classification[target_html_row] <- "target_result_html"
delta$allowed[target_html_row] <- TRUE

site_index_rows <- delta$path %in% c("search.json", "sitemap.xml") &
  delta$change_type == "content_changed"
delta$classification[site_index_rows] <- "normal_target_render_site_index"
delta$allowed[site_index_rows] <- TRUE

target_resource_touch <- delta$path ==
  "notebooks/hypotheses/H02_files/figure-html/fig-h02-paired-placement-curves-1.png" &
  delta$change_type == "mtime_only"
delta$classification[target_resource_touch] <- "byte_identical_target_resource_refresh"
delta$allowed[target_resource_touch] <- TRUE

shared_asset_touch <- delta$path ==
  "site_libs/bootstrap/bootstrap-a2a938b4dd5711f7a799c87bd16ba44c.min.css" &
  delta$change_type == "mtime_only"
delta$classification[shared_asset_touch] <- "byte_identical_shared_asset_touch"
delta$allowed[shared_asset_touch] <- TRUE

write_evidence(delta, "build_delta_postrender.csv")
build_summary <- aggregate(
  rep(1L, nrow(delta)),
  by = list(
    change_type = delta$change_type,
    classification = delta$classification,
    allowed = delta$allowed
  ),
  FUN = sum
)
names(build_summary)[[4L]] <- "rows"
write_evidence(build_summary, "build_change_classification_postrender.csv")

# Reader-test post-render contract audit. These are test-contract checks only.
historical_mismatch <- function(path) {
  manifest <- utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  files <- file.path(root, manifest$path)
  exists <- file.exists(files)
  current_sha256 <- rep(NA_character_, length(files))
  current_bytes <- rep(NA_real_, length(files))
  current_sha256[exists] <- vapply(files[exists], artifact_sha256, character(1))
  current_bytes[exists] <- as.numeric(file.info(files[exists])$size)
  sort(manifest$path[
    !exists |
      current_sha256 != manifest$sha256 |
      current_bytes != manifest$bytes
  ])
}

preparation_manifest <- "artifacts/12_manifests/H02/H02_preparation_report_manifest.csv"
worker_manifest <- "artifacts/12_manifests/H02/H02_worker_output_hashes.csv"
html_path <- "_build/nathealth/notebooks/hypotheses/H02.html"

expected_preparation_mismatches <- sort(c(
  "_quarto-nathealth.yml",
  "audit/hypotheses/H02/H02_analysis_preparation.qmd",
  "notebooks/hypotheses/H02.qmd"
))
expected_worker_mismatches <- sort(c(
  "audit/handoffs/H02_shared_change_request.md",
  "audit/hypotheses/H02/H02_analysis_preparation.qmd",
  "notebooks/hypotheses/H02.qmd",
  "tests/hypotheses/H02/test_h02_paired_placement_display.R",
  "tests/hypotheses/H02/test_h02_preparation_report.R",
  "tests/hypotheses/H02/test_h02_reader_report.R"
))
current_preparation_mismatches <- historical_mismatch(preparation_manifest)
current_worker_mismatches <- historical_mismatch(worker_manifest)
expected_stale_html <-
  "df73f2f87d6d3bdc9acd44493a113e18b510884f0ecb8e2214b39dc3d71cb164"
current_html <- artifact_sha256(html_path)

reader_contract <- data.frame(
  assertion = c(
    "preparation manifest historical mismatch set",
    "worker manifest historical mismatch set",
    "rendered H02 HTML SHA-256"
  ),
  expected = c(
    collapse_paths(expected_preparation_mismatches),
    collapse_paths(expected_worker_mismatches),
    expected_stale_html
  ),
  current = c(
    collapse_paths(current_preparation_mismatches),
    collapse_paths(current_worker_mismatches),
    current_html
  ),
  difference = c(
    collapse_paths(setdiff(current_preparation_mismatches, expected_preparation_mismatches)),
    collapse_paths(setdiff(current_worker_mismatches, expected_worker_mismatches)),
    "target HTML was replaced by the authorized render"
  ),
  pass = c(
    identical(current_preparation_mismatches, expected_preparation_mismatches),
    identical(current_worker_mismatches, expected_worker_mismatches),
    identical(current_html, expected_stale_html)
  ),
  stringsAsFactors = FALSE
)
write_evidence(reader_contract, "reader_test_contract_audit.csv")

# Consolidated fail-closed defects and intentionally unstarted visual gate.
link_audit <- read_evidence("reader_link_audit.csv")
broken_links <- link_audit[!link_audit$pass, ]
stopifnot(nrow(broken_links) == 1L)

defects <- data.frame(
  defect_id = c("H02-33F-D1", "H02-33F-D2"),
  gate = c("complete reader test", "rendered-reader link integrity"),
  classification = c("stale verification contract", "broken local build link"),
  evidence = c(
    paste0(
      "The complete reader test pins the pre-render H02 HTML hash and historical ",
      "manifest mismatch sets that omit the rendered H02 HTML; all three assertions ",
      "are false after the authorized target render."
    ),
    paste0(
      "Link '", broken_links$link_text[[1L]], "' resolves to '",
      broken_links$href[[1L]], "', but the target is absent from _build/nathealth."
    )
  ),
  source_or_scientific_change = FALSE,
  blocking = TRUE,
  disposition = "FAIL_CLOSED_NO_PATCH_NO_RERENDER",
  stringsAsFactors = FALSE
)
write_evidence(defects, "consolidated_defects.csv")

loopback <- data.frame(
  stage = c("static_server", "browser_initialization", "visual_QA", "teardown"),
  status = c(
    "NOT_STARTED_NONVISUAL_GATE_FAILURE",
    "NOT_STARTED_NONVISUAL_GATE_FAILURE",
    "NOT_STARTED_NONVISUAL_GATE_FAILURE",
    "NOT_APPLICABLE_NO_SERVER_OR_BROWSER_STARTED"
  ),
  process_or_listener = c(FALSE, FALSE, FALSE, FALSE),
  reason = c(
    "Complete reader test and link-integrity gates did not pass.",
    "Complete reader test and link-integrity gates did not pass.",
    "Complete reader test and link-integrity gates did not pass.",
    "No loopback process was started."
  ),
  stringsAsFactors = FALSE
)
write_evidence(loopback, "loopback_lifecycle.csv")

harness <- data.frame(
  attempt = 1:2,
  script = "audit_h02_order33f_html.R",
  disposition = c("HARNESS_ERROR", "PRODUCT_GATE_FAILURE"),
  detail = c(
    "Audit-only script stopped on an empty second argument to as.numeric(); the evidence script was corrected without touching a source, artifact, or rendered output.",
    "All semantic reversal checks passed; the audit stopped because one rendered local link target is absent."
  ),
  stringsAsFactors = FALSE
)
write_evidence(harness, "semantic_audit_execution.csv")

stopifnot(
  protected_summary$pass,
  all(delta$allowed),
  sum(!reader_contract$pass) == 3L,
  all(read_evidence("semantic_reverse_audit.csv")$pass),
  nrow(defects) == 2L
)

cat(sprintf(
  paste0(
    "EVIDENCE_FINALIZATION=PASS protected=%d/%d build_delta=%d/%d ",
    "reader_contract_failures=%d defects=%d\n"
  ),
  sum(protected$byte_exact),
  nrow(protected),
  sum(delta$allowed),
  nrow(delta),
  sum(!reader_contract$pass),
  nrow(defects)
))
