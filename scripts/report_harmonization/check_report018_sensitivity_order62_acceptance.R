#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_dir <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_battery_order62_render"
)
output_dir <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_battery_order62_acceptance"
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

file_bytes <- function(path) unname(as.numeric(file.info(path)$size))

raw_identical <- function(path_a, path_b) {
  identical(
    readBin(path_a, what = "raw", n = file_bytes(path_a)),
    readBin(path_b, what = "raw", n = file_bytes(path_b))
  )
}

checks <- list()
add_check <- function(domain, check_id, pass, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(
    domain = domain,
    check_id = check_id,
    pass = isTRUE(pass),
    detail = as.character(detail),
    stringsAsFactors = FALSE
  )
}

manifest_specs <- data.frame(
  path = c(
    "audit/report_harmonization/report018_sensitivity_order62_dispatch_manifest.csv",
    "audit/report_harmonization/report018_sensitivity_order62_dispatch_receipt_manifest.csv",
    "audit/report_harmonization/report018_sensitivity_order62_prerender_matrix_addendum_manifest.csv",
    "audit/report_harmonization/report018_sensitivity_order62_no_rerender_classification_manifest.csv",
    "audit/report_harmonization/report018_sensitivity_order62_no_rerender_wrapper_recovery_manifest.csv",
    "audit/report_harmonization/report018_sensitivity_order62_link_target_import_recovery_manifest.csv"
  ),
  expected_rows = c(29L, 6L, 16L, 16L, 12L, 10L),
  stringsAsFactors = FALSE
)

manifest_rows <- list()
for (spec_index in seq_len(nrow(manifest_specs))) {
  manifest_path <- manifest_specs$path[[spec_index]]
  manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
  exists <- file.exists(manifest$path) & !dir.exists(manifest$path)
  live_sha256 <- rep(NA_character_, nrow(manifest))
  live_bytes <- rep(NA_real_, nrow(manifest))
  live_sha256[exists] <- vapply(
    manifest$path[exists],
    sha256_file,
    character(1)
  )
  live_bytes[exists] <- file_bytes(manifest$path[exists])
  exact <- exists &
    live_sha256 == manifest$sha256 &
    live_bytes == as.numeric(manifest$bytes)

  authorized_target_transition <- manifest$path ==
    "_build/nathealth/notebooks/sensitivity_battery.html" &
    manifest$sha256 ==
      "b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780" &
    live_sha256 ==
      "875f53995f5f47ec30b630a5cf47edfef1d0fe925034d3fab4944be8c6c6b4be" &
    live_bytes == 54637

  stopped_check_transition <- manifest$path ==
    file.path(
      evidence_dir,
      "postrender_checks_postrender.csv"
    ) &
    manifest$sha256 ==
      "f33740e0e3ef03333c3f8ab02371dbcb8505fd81bb99c98718edefabdb81be92" &
    live_sha256 ==
      "05ba9e419768ec32bf7dc4562f753c15079ad4ffc104df34fc70733ba84f3c79"
  stopped_check_recovered <- file.path(
    evidence_dir,
    "initial_checker_stop/postrender_checks_postrender.csv"
  )
  stopped_check_transition <- stopped_check_transition &
    file.exists(stopped_check_recovered) &
    sha256_file(stopped_check_recovered) ==
      "f33740e0e3ef03333c3f8ab02371dbcb8505fd81bb99c98718edefabdb81be92"

  authorized <- exact | authorized_target_transition | stopped_check_transition
  disposition <- ifelse(
    exact,
    "LIVE_EXACT",
    ifelse(
      authorized_target_transition,
      "AUTHORIZED_TARGET_RENDER_TRANSITION",
      ifelse(
        stopped_check_transition,
        "RECOVERED_STOPPED_CHECK_TRANSITION",
        "UNAUTHORIZED_MISMATCH"
      )
    )
  )
  manifest_rows[[spec_index]] <- data.frame(
    manifest_path = manifest_path,
    path = manifest$path,
    sealed_sha256 = manifest$sha256,
    live_sha256 = live_sha256,
    sealed_bytes = manifest$bytes,
    live_bytes = live_bytes,
    disposition = disposition,
    authorized = authorized,
    stringsAsFactors = FALSE
  )
  add_check(
    "historical seals",
    paste0("manifest_", spec_index, "_exact_or_classified"),
    nrow(manifest) == manifest_specs$expected_rows[[spec_index]] &&
      !anyDuplicated(manifest$path) &&
      !manifest_path %in% manifest$path &&
      all(authorized),
    sprintf(
      "rows=%d live_exact=%d classified=%d",
      nrow(manifest),
      sum(exact),
      sum(!exact & authorized)
    )
  )
}
manifest_audit <- do.call(rbind, manifest_rows)
readr::write_csv(
  manifest_audit,
  file.path(output_dir, "historical_manifest_audit.csv")
)

fixed <- data.frame(
  path = c(
    "notebooks/sensitivity_battery.qmd",
    "_build/nathealth/notebooks/sensitivity_battery.html",
    "_quarto-nathealth.yml",
    "renv.lock",
    "audit/decisions/manuscript_prepared_data_sensitivity.md",
    "_build/nathealth/audit/decisions/manuscript_prepared_data_sensitivity.md",
    "audit/report_harmonization/coordination_matrix.csv",
    "audit/report_harmonization/phase4_corpus_manifest.csv"
  ),
  expected_sha256 = c(
    "d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70",
    "875f53995f5f47ec30b630a5cf47edfef1d0fe925034d3fab4944be8c6c6b4be",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "4f61db934f341127168fc84199e733a7b5eb25c06b3924e24c019732a75b7f2f",
    "4f61db934f341127168fc84199e733a7b5eb25c06b3924e24c019732a75b7f2f",
    "7a6ce0ee4b2c97dea27d18ad3fed9759f580484ea046a2cf645ab5993f714842",
    "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334"
  ),
  stringsAsFactors = FALSE
)
fixed$exists <- file.exists(fixed$path) & !dir.exists(fixed$path)
fixed$live_sha256 <- NA_character_
fixed$live_sha256[fixed$exists] <- vapply(
  fixed$path[fixed$exists],
  sha256_file,
  character(1)
)
fixed$exact <- fixed$exists & fixed$live_sha256 == fixed$expected_sha256
readr::write_csv(fixed, file.path(output_dir, "fixed_identity_audit.csv"))
add_check(
  "identity",
  "source_target_profile_lock_resource_matrix_and_corpus_exact",
  all(fixed$exact),
  sprintf("exact=%d/%d", sum(fixed$exact), nrow(fixed))
)

render_execution <- readr::read_csv(
  file.path(evidence_dir, "render_execution.csv"),
  show_col_types = FALSE
)
render_lookup <- setNames(render_execution$value, render_execution$field)
render_pass <- nrow(render_execution) == 9L &&
  all(render_execution$status == "PASS") &&
  identical(render_lookup[["command_count"]], "1") &&
  identical(render_lookup[["exit_status"]], "0") &&
  identical(render_lookup[["semantic_disposition"]], "NO_GT") &&
  identical(render_lookup[["semantic_tables"]], "0") &&
  identical(render_lookup[["semantic_ids"]], "0") &&
  identical(render_lookup[["semantic_headers"]], "0") &&
  identical(render_lookup[["semantic_substitutions"]], "0") &&
  identical(
    render_lookup[["target_sha256"]],
    "875f53995f5f47ec30b630a5cf47edfef1d0fe925034d3fab4944be8c6c6b4be"
  )
add_check(
  "render",
  "exactly_one_target_render_completed",
  render_pass,
  "command_count=1 exit=0 semantic=NO_GT"
)

semantic <- readr::read_csv(
  file.path(evidence_dir, "gt_html_semantic_post_render_summary.csv"),
  show_col_types = FALSE
)
semantic_ledger <- ifelse(is.na(semantic$ledger_file), "", semantic$ledger_file)
semantic_pass <- nrow(semantic) == 1L &&
  semantic$target == "_build/nathealth/notebooks/sensitivity_battery.html" &&
  semantic$disposition == "NO_GT" &&
  semantic$pre_sha256 ==
    fixed$live_sha256[
      fixed$path == "_build/nathealth/notebooks/sensitivity_battery.html"
    ] &&
  semantic$post_sha256 == semantic$pre_sha256 &&
  semantic$pre_bytes == 54637 &&
  semantic$post_bytes == 54637 &&
  semantic$table_count == 0L &&
  semantic$id_count == 0L &&
  semantic$headers_count == 0L &&
  semantic$total_substitutions == 0L &&
  semantic_ledger == ""
add_check(
  "semantic",
  "no_gt_summary_exact",
  semantic_pass,
  "tables=0 ids=0 headers=0 substitutions=0"
)

document <- xml2::read_html(
  "_build/nathealth/notebooks/sensitivity_battery.html"
)
main_nodes <- xml2::xml_find_all(
  document,
  "//main[@id='quarto-document-content']"
)
headings <- trimws(xml2::xml_text(xml2::xml_find_all(
  main_nodes,
  ".//h1 | .//h2"
)))
ids <- xml2::xml_attr(xml2::xml_find_all(document, ".//*[@id]"), "id")
ids <- ids[!is.na(ids) & nzchar(ids)]
dom_pass <- length(main_nodes) == 1L &&
  identical(
    headings,
    c(
      "Planned sensitivity checks",
      "Purpose",
      "Manuscript-prepared-data sensitivity",
      "What this notebook uses and produces"
    )
  ) &&
  length(xml2::xml_find_all(main_nodes, ".//table")) == 0L &&
  length(xml2::xml_find_all(main_nodes, ".//figure")) == 0L &&
  length(xml2::xml_find_all(
    main_nodes,
    ".//*[contains(@class, 'cell-output')]"
  )) ==
    0L &&
  length(xml2::xml_find_all(main_nodes, ".//*[contains(@class, 'error')]")) ==
    0L &&
  !anyDuplicated(ids)
add_check(
  "DOM",
  "target_structure_and_nonexecution_exact",
  dom_pass,
  sprintf(
    "main=%d headings=%d duplicate_ids=%d",
    length(main_nodes),
    length(headings),
    anyDuplicated(ids)
  )
)

link_audit <- readr::read_csv(
  file.path(evidence_dir, "link_audit_postqa.csv"),
  show_col_types = FALSE
)
link_pass <- nrow(link_audit) == 44L &&
  all(link_audit$exists) &&
  all(link_audit$fragment_resolves)
add_check(
  "links",
  "all_internal_links_and_fragments_resolve",
  link_pass,
  sprintf(
    "resolved=%d/%d",
    sum(link_audit$exists & link_audit$fragment_resolves),
    nrow(link_audit)
  )
)

postrender_checks <- readr::read_csv(
  file.path(evidence_dir, "postrender_checks_postqa.csv"),
  show_col_types = FALSE
)
preflight_checks <- readr::read_csv(
  file.path(evidence_dir, "prerender_preflight/preflight_checks.csv"),
  show_col_types = FALSE
)
test_runs <- readr::read_csv(
  file.path(evidence_dir, "prerender_preflight/read_only_test_runs.csv"),
  show_col_types = FALSE
)
add_check(
  "contracts",
  "preflight_postrender_and_structural_tests_pass",
  nrow(preflight_checks) == 10L &&
    all(preflight_checks$pass) &&
    nrow(postrender_checks) == 6L &&
    all(postrender_checks$pass) &&
    nrow(test_runs) == 4L &&
    all(test_runs$pass) &&
    all(test_runs$exit_status == 0L),
  "preflight=10/10 postrender=6/6 tests=4/4"
)

visual <- readr::read_csv(
  file.path(evidence_dir, "visual_qa.csv"),
  show_col_types = FALSE
)
screenshots <- readr::read_csv(
  file.path(evidence_dir, "visual_screenshot_manifest.csv"),
  show_col_types = FALSE
)
screenshot_exists <- file.exists(screenshots$path) &
  !dir.exists(screenshots$path)
screenshot_sha256 <- rep(NA_character_, nrow(screenshots))
screenshot_sha256[screenshot_exists] <- vapply(
  screenshots$path[screenshot_exists],
  sha256_file,
  character(1)
)
screenshot_bytes <- rep(NA_real_, nrow(screenshots))
screenshot_bytes[screenshot_exists] <- file_bytes(screenshots$path[
  screenshot_exists
])
served <- readr::read_csv(
  file.path(evidence_dir, "served_http_checks.csv"),
  show_col_types = FALSE
)
lifecycle <- readr::read_csv(
  file.path(evidence_dir, "server_lifecycle.csv"),
  show_col_types = FALSE
)
console <- trimws(paste(
  readLines(
    file.path(evidence_dir, "browser_console_warnings_errors.json"),
    warn = FALSE
  ),
  collapse = "\n"
))
visual_pass <- nrow(visual) == 8L &&
  all(visual$pass) &&
  nrow(screenshots) == 6L &&
  all(screenshots$valid_image) &&
  all(screenshots$actual_format %in% c("png", "jpeg")) &&
  all(screenshot_exists) &&
  all(screenshot_sha256 == screenshots$sha256) &&
  all(screenshot_bytes == as.numeric(screenshots$bytes)) &&
  nrow(served) == 4L &&
  all(served$status == 200L) &&
  all(served$pass) &&
  all(lifecycle$status[lifecycle$field != "optional_favicon"] == "PASS") &&
  console == "[]"
add_check(
  "visual",
  "bounded_loopback_visual_qa_and_teardown_pass",
  visual_pass,
  "checks=8/8 screenshots=6/6 routes=4/4 console=0 listener=none"
)

audit_inventory <- function(snapshot, build = FALSE) {
  base_path <- if (build) "_build/nathealth" else "."
  full_paths <- if (build) file.path(base_path, snapshot$path) else
    snapshot$path
  is_directory <- if (build) snapshot$type == "directory" else
    rep(FALSE, nrow(snapshot))
  exists <- ifelse(
    is_directory,
    dir.exists(full_paths),
    file.exists(full_paths)
  )
  live_sha256 <- rep(NA_character_, nrow(snapshot))
  live_bytes <- rep(NA_real_, nrow(snapshot))
  file_rows <- exists & !is_directory
  live_sha256[file_rows] <- vapply(
    full_paths[file_rows],
    sha256_file,
    character(1)
  )
  live_bytes[file_rows] <- file_bytes(full_paths[file_rows])
  expected_links <- ifelse(
    is.na(snapshot$link_target),
    "",
    snapshot$link_target
  )
  live_links <- rep("", nrow(snapshot))
  live_links[exists] <- Sys.readlink(full_paths[exists])
  exact <- exists &
    ifelse(
      is_directory,
      live_links == expected_links,
      live_sha256 == snapshot$sha256 &
        live_bytes == as.numeric(snapshot$bytes) &
        live_links == expected_links
    )
  list(exact = exact, links = live_links)
}

build_postrender_path <- file.path(
  evidence_dir,
  "build_inventory_postrender.csv"
)
build_postqa_path <- file.path(evidence_dir, "build_inventory_postqa.csv")
protected_postrender_path <- file.path(
  evidence_dir,
  "protected_inventory_postrender.csv"
)
protected_postqa_path <- file.path(
  evidence_dir,
  "protected_inventory_postqa.csv"
)
build_snapshot <- readr::read_csv(build_postqa_path, show_col_types = FALSE)
protected_snapshot <- readr::read_csv(
  protected_postqa_path,
  show_col_types = FALSE
)
build_live <- audit_inventory(build_snapshot, build = TRUE)
protected_live <- audit_inventory(protected_snapshot, build = FALSE)
inventory_pass <- raw_identical(build_postrender_path, build_postqa_path) &&
  raw_identical(protected_postrender_path, protected_postqa_path) &&
  nrow(build_snapshot) == 1180L &&
  sum(build_snapshot$type == "file") == 871L &&
  sum(build_snapshot$type == "directory") == 309L &&
  nrow(protected_snapshot) == 12991L &&
  all(build_live$exact) &&
  all(protected_live$exact) &&
  !any(nzchar(build_live$links)) &&
  !any(nzchar(protected_live$links))
inventory_audit <- data.frame(
  inventory = c("build", "protected"),
  members = c(nrow(build_snapshot), nrow(protected_snapshot)),
  live_exact = c(sum(build_live$exact), sum(protected_live$exact)),
  symlinks = c(
    sum(nzchar(build_live$links)),
    sum(nzchar(protected_live$links))
  ),
  stringsAsFactors = FALSE
)
readr::write_csv(
  inventory_audit,
  file.path(output_dir, "inventory_live_audit.csv")
)
add_check(
  "stability",
  "postrender_postqa_and_live_inventories_exact",
  inventory_pass,
  "build=1180/1180 protected=12991/12991 symlinks=0"
)

matrix <- readr::read_csv(
  "audit/report_harmonization/coordination_matrix.csv",
  show_col_types = FALSE
)
shared_row <- matrix[matrix$logical_order == "00", , drop = FALSE]
matrix_pass <- nrow(matrix) == 15L &&
  ncol(matrix) == 16L &&
  nrow(shared_row) == 1L &&
  shared_row$current_task_status_2026_08_12 ==
    "active_order62_sensitivity_battery_target_render" &&
  shared_row$harmonization_review_status ==
    "report018_order62_sensitivity_battery_target_render_released"
add_check(
  "coordination",
  "order62_active_state_is_unique",
  matrix_pass,
  "matrix=15x16 shared_active=1"
)

required_stop_evidence <- c(
  file.path(
    evidence_dir,
    "initial_checker_stop/postrender_checks_postrender.csv"
  ),
  file.path(evidence_dir, "initial_visual_sealer_stop.md"),
  file.path(evidence_dir, "image_format_sealer_stop.md"),
  file.path(
    evidence_dir,
    "preqa_complete_validation/preqa_validation_manifest.csv"
  ),
  file.path(evidence_dir, "completion_checker_postqa_output.txt")
)
completion_output <- paste(
  readLines(
    file.path(evidence_dir, "completion_checker_postqa_output.txt"),
    warn = FALSE
  ),
  collapse = "\n"
)
add_check(
  "evidence",
  "stopped_harness_and_final_completion_evidence_retained",
  all(file.exists(required_stop_evidence)) &&
    grepl(
      "REPORT018_SENSITIVITY_ORDER62_FINAL_WRAPPER=PASS",
      completion_output,
      fixed = TRUE
    ),
  "initial checker, two visual sealer stops, pre-QA validation, final completion retained"
)

checks_frame <- do.call(rbind, checks)
readr::write_csv(checks_frame, file.path(output_dir, "acceptance_checks.csv"))
stopifnot(nrow(checks_frame) == 16L, all(checks_frame$pass))

cat(sprintf(
  paste0(
    "REPORT018_SENSITIVITY_ORDER62_ACCEPTANCE=PASS checks=%d/%d ",
    "historical_rows=%d target=%s build=1180 protected=12991 ",
    "visual=8/8 R=%s\n"
  ),
  sum(checks_frame$pass),
  nrow(checks_frame),
  nrow(manifest_audit),
  sha256_file("_build/nathealth/notebooks/sensitivity_battery.html"),
  as.character(getRversion())
))
