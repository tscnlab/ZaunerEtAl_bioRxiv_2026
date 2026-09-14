#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
stopifnot(dir.exists(project_library))
.libPaths(c(project_library, .libPaths()))

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(readr)
})

stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  Sys.getenv("RENV_CONFIG_AUTOLOADER_ENABLED", unset = "") == "FALSE"
)

owner_relative <-
  "audit/hypotheses/H07/report018_order72j_split_svg_export"
owner_root <- normalizePath(
  file.path(root, owner_relative),
  winslash = "/",
  mustWork = TRUE
)
evidence_dir <- file.path(owner_root, "evidence")
candidate_path <- file.path(
  owner_root,
  "candidate/H07_revised_smooth_derivative_pairs_near_eye.svg"
)
attempt_path <- file.path(
  owner_root,
  "attempts/attempt_01/H07_revised_smooth_derivative_pairs_near_eye.svg"
)
handoff_path <- file.path(
  owner_root,
  "REPORT018-ORDER72J-COMPONENT-REVIEW.md"
)
manifest_path <- file.path(owner_root, "non_circular_manifest.csv")
stopifnot(
  dir.exists(evidence_dir),
  file.exists(candidate_path),
  file.exists(attempt_path),
  !file.exists(handoff_path),
  !file.exists(manifest_path)
)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

assert_owner_target <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  stopifnot(startsWith(normalized, paste0(owner_root, "/")))
  normalized
}

write_evidence <- function(object, filename) {
  target <- assert_owner_target(file.path(evidence_dir, filename))
  stopifnot(!file.exists(target))
  utils::write.csv(
    object,
    target,
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

resolve_path <- function(path) {
  ifelse(startsWith(path, "/"), path, file.path(root, path))
}

rehash_manifest <- function(manifest, expected_rows, label) {
  stopifnot(
    identical(names(manifest), c("path", "sha256", "bytes")),
    nrow(manifest) == expected_rows,
    !anyDuplicated(manifest$path)
  )
  resolved <- resolve_path(manifest$path)
  exists <- file.exists(resolved)
  observed_sha256 <- rep(NA_character_, length(resolved))
  observed_bytes <- rep(NA_real_, length(resolved))
  observed_sha256[exists] <- vapply(
    resolved[exists],
    sha256_file,
    character(1)
  )
  observed_bytes[exists] <- as.numeric(file.info(resolved[exists])$size)
  result <- data.frame(
    scope = label,
    path = manifest$path,
    expected_sha256 = manifest$sha256,
    observed_sha256 = observed_sha256,
    expected_bytes = manifest$bytes,
    observed_bytes = observed_bytes,
    exists = exists,
    status = ifelse(
      exists &
        observed_sha256 == manifest$sha256 &
        observed_bytes == manifest$bytes,
      "PASS",
      "FAIL"
    ),
    stringsAsFactors = FALSE
  )
  stopifnot(all(result$status == "PASS"))
  result
}

release_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72j_component_exports_release"
)
release_manifest_path <- file.path(release_root, "release_manifest.csv")
input_pin_path <- file.path(release_root, "H07_execution_input_pins.csv")
preservation_path <- file.path(release_root, "H07_preservation_inventory.csv")
order_path <- file.path(
  root,
  paste0(
    "audit/report_harmonization/owner_orders/",
    "72j_native_svg_component_exports_and_optional_compatibility.md"
  )
)
acceptance_path <- file.path(
  release_root,
  "independent_preflight_acceptance.md"
)

authority <- data.frame(
  path = c(
    substring(order_path, nchar(root) + 2L),
    substring(acceptance_path, nchar(root) + 2L),
    substring(release_manifest_path, nchar(root) + 2L),
    substring(input_pin_path, nchar(root) + 2L),
    substring(preservation_path, nchar(root) + 2L)
  ),
  expected_sha256 = c(
    "ed7c0b94b5ad380e1ec8b29d09aec07eedda9fdfa5c5ad8752f2b9dd913e182a",
    "8e5d95479865fa4b71f11a133ae08b6aa2b067976305b190f267ac14d8514cd3",
    "66de5e9a17875b29616c2558994ed6724c61e9179c518da4d143e8f33ae97e8f",
    "683c0ee307d3f3bfc9926ca6eb05b735f21260baecb0354fc583bfda0d573496",
    "e8bfc8031fd40796927c8b245a6767a587c3bd17e3f82facb3f142c68a327aaa"
  ),
  stringsAsFactors = FALSE
)
authority_files <- file.path(root, authority$path)
authority$observed_sha256 <- vapply(
  authority_files,
  sha256_file,
  character(1)
)
authority$bytes <- as.numeric(file.info(authority_files)$size)
authority$status <- ifelse(
  authority$expected_sha256 == authority$observed_sha256,
  "PASS",
  "FAIL"
)
stopifnot(all(authority$status == "PASS"))

release_manifest <- readr::read_csv(
  release_manifest_path,
  show_col_types = FALSE
)
input_pins <- readr::read_csv(input_pin_path, show_col_types = FALSE)
preservation <- readr::read_csv(preservation_path, show_col_types = FALSE)
release_post <- rehash_manifest(release_manifest, 123L, "release manifest")
input_post <- rehash_manifest(input_pins, 39L, "H07 execution inputs")
preservation_post <- rehash_manifest(
  preservation,
  1451L,
  "H07 preservation inventory"
)

release_pre <- readr::read_csv(
  file.path(evidence_dir, "release_manifest_rehash.csv"),
  show_col_types = FALSE
)
input_pre <- readr::read_csv(
  file.path(evidence_dir, "execution_input_rehash_pre.csv"),
  show_col_types = FALSE
)
preservation_pre <- readr::read_csv(
  file.path(evidence_dir, "preservation_rehash_pre.csv"),
  show_col_types = FALSE
)
same_rehash <- function(pre, post) {
  identical(pre$path, post$path) &&
    identical(pre$expected_sha256, post$expected_sha256) &&
    identical(pre$observed_sha256, post$observed_sha256) &&
    all(pre$expected_bytes == post$expected_bytes) &&
    all(pre$observed_bytes == post$observed_bytes) &&
    identical(pre$exists, post$exists) &&
    all(pre$status == "PASS") &&
    all(post$status == "PASS")
}
stopifnot(
  same_rehash(release_pre, release_post),
  same_rehash(input_pre, input_post),
  same_rehash(preservation_pre, preservation_post)
)

write_evidence(authority, "authority_rehash_post.csv")
write_evidence(release_post, "release_manifest_rehash_post.csv")
write_evidence(input_post, "execution_input_rehash_post.csv")
write_evidence(preservation_post, "preservation_rehash_post.csv")

candidate_expected_sha256 <-
  "f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57"
candidate_expected_bytes <- 1238493
candidate_identity <- readr::read_csv(
  file.path(evidence_dir, "candidate_identity.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(candidate_identity) == 1L,
  candidate_identity$sha256 == candidate_expected_sha256,
  candidate_identity$bytes == candidate_expected_bytes,
  candidate_identity$actual_svg_trials == 1L,
  candidate_identity$renderer_corrections == 0L,
  sha256_file(candidate_path) == candidate_expected_sha256,
  sha256_file(attempt_path) == candidate_expected_sha256,
  file.info(candidate_path)$size == candidate_expected_bytes,
  file.info(attempt_path)$size == candidate_expected_bytes
)

static_evidence_files <- c(
  "candidate_numeric_input_checks.csv",
  "candidate_layer_row_checks.csv",
  "candidate_label_and_panel_order_checks.csv",
  "candidate_svg_tag_census.csv",
  "candidate_svg_colour_census.csv",
  "candidate_visible_text_checks.csv",
  "candidate_svg_structure_checks.csv"
)
static_status <- vapply(
  file.path(evidence_dir, static_evidence_files),
  function(path) {
    frame <- readr::read_csv(path, show_col_types = FALSE)
    status_columns <- intersect(c("status", "validation_status"), names(frame))
    length(status_columns) > 0L &&
      all(unlist(frame[status_columns], use.names = FALSE) == "PASS")
  },
  logical(1)
)
stopifnot(all(static_status))

code_files <- c(
  "code/01_preflight_and_input_audit.R",
  "code/02a_preexport_boundary_check.R",
  "code/02_export_attempt_01.R",
  "code/03_validate_and_seal_candidate.R",
  "code/04_finalize_awaiting_acceptance.R"
)
code_paths <- file.path(owner_root, code_files)
stopifnot(all(file.exists(code_paths)))
code_identities <- data.frame(
  path = file.path(owner_relative, code_files),
  sha256 = vapply(code_paths, sha256_file, character(1)),
  bytes = as.numeric(file.info(code_paths)$size),
  role = c(
    "preflight and frozen-input audit",
    "pre-export implementation boundary",
    "frozen-source native SVG export implementation",
    "independent static validation and candidate seal",
    "post-protection and awaiting-acceptance finalizer"
  ),
  stringsAsFactors = FALSE
)
stopifnot(
  code_identities$sha256[code_files == "code/02_export_attempt_01.R"] ==
    "08d9fe473b24374f2d6f569344adf7ae3835168253c7ceb18d07629fb859a34f"
)
write_evidence(code_identities, "implementation_identities.csv")

failure_files <- c(
  "attempts/preflight_01/construction_failure.csv",
  "attempts/preexport_boundary_01/construction_failure.csv",
  "attempts/implementation_run_01_predevice/construction_failure.csv",
  "attempts/implementation_run_02_predevice/construction_failure.csv",
  "attempts/static_validation_run_01/construction_failure.csv",
  "attempts/static_validation_run_02/construction_failure.csv"
)
stopifnot(all(file.exists(file.path(owner_root, failure_files))))
attempt_inventory <- data.frame(
  sequence = 1:9,
  stage = c(
    "preflight_01",
    "preflight_corrected",
    "preexport_boundary_01",
    "implementation_run_01_predevice",
    "implementation_run_02_predevice",
    "native_svg_attempt_01",
    "static_validation_run_01",
    "static_validation_run_02",
    "static_validation_run_03"
  ),
  status = c(
    "STOPPED_CHECKER_ROW_COUNT",
    "PASS",
    "STOPPED_CONTRACT_LITERAL_OMISSION",
    "STOPPED_PREDEVICE_NAMED_PATH_LOOKUP",
    "STOPPED_PREDEVICE_TIDYSELECT_WARNING",
    "PASS_EXPORTED",
    "STOPPED_CHECKER_TYPE_STRICTNESS",
    "STOPPED_CHECKER_ABSENT_TAG_LOOKUP",
    "PASS_STATIC_AND_CANDIDATE_SEALED"
  ),
  svg_device_invoked = c(
    FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE
  ),
  svg_created = c(
    FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE
  ),
  candidate_created = c(
    FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE
  ),
  scientific_computation = FALSE,
  renderer_correction = FALSE,
  evidence = c(
    failure_files[[1L]],
    "evidence/preflight_authority.csv",
    failure_files[[2L]],
    failure_files[[3L]],
    failure_files[[4L]],
    "evidence/attempt_01_export_record.csv",
    failure_files[[5L]],
    failure_files[[6L]],
    "evidence/candidate_identity.csv"
  ),
  stringsAsFactors = FALSE
)
stopifnot(
  sum(attempt_inventory$svg_device_invoked) == 1L,
  sum(attempt_inventory$svg_created) == 1L,
  sum(attempt_inventory$renderer_correction) == 0L
)
write_evidence(attempt_inventory, "attempt_inventory.csv")

command_prefix <- paste(
  "env RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
  paste0("NATHEALTH_PROJECT_ROOT=", root),
  "Rscript --vanilla"
)
command_inventory <- data.frame(
  command_group = c(
    "preflight",
    "pre-export boundary",
    "native SVG export",
    "static validation and candidate seal",
    "finalization"
  ),
  exact_command = c(
    paste(
      command_prefix,
      file.path(owner_relative, "code/01_preflight_and_input_audit.R")
    ),
    paste(
      command_prefix,
      file.path(owner_relative, "code/02a_preexport_boundary_check.R")
    ),
    paste(
      command_prefix,
      file.path(owner_relative, "code/02_export_attempt_01.R")
    ),
    paste(
      command_prefix,
      file.path(owner_relative, "code/03_validate_and_seal_candidate.R")
    ),
    paste(
      command_prefix,
      file.path(owner_relative, "code/04_finalize_awaiting_acceptance.R")
    )
  ),
  terminal_result = c(
    "PASS after one preserved checker construction stop",
    "PASS after one preserved literal-audit construction stop",
    "PASS after two preserved pre-device construction stops; one SVG device invocation",
    "PASS after two preserved checker construction stops; candidate copied byte-identically",
    "PASS when this record and final manifest are emitted"
  ),
  persistent_process_started = FALSE,
  stringsAsFactors = FALSE
)
write_evidence(command_inventory, "command_inventory.csv")

visual_qa <- data.frame(
  component = "H07 S7-B near-eye paired smooth and derivative SVG",
  serial_visual_qa_lease = "NOT_ISSUED",
  browser_surface = "NOT_OPENED",
  loopback_listener = "NOT_STARTED",
  original_size_review = "NOT_RUN",
  width_170_mm_review = "NOT_RUN",
  width_708_px_review = "NOT_RUN",
  accepted_png_comparison = "NOT_RUN",
  defect_status = "NOT_ASSESSED",
  reason = paste(
    "Order72j requires the owner to stop after candidate and static completion",
    "until the Harmonizer grants the serial visual-QA lease"
  ),
  next_gate = "REPORT018-ORDER72J-COMPONENT-REVIEW",
  stringsAsFactors = FALSE
)
write_evidence(visual_qa, "visual_qa_status.csv")

teardown <- data.frame(
  item = c(
    "task-created browser tabs",
    "task-created loopback listeners",
    "task-created serving roots",
    "persistent task-created processes",
    "completed R processes"
  ),
  created = c(FALSE, FALSE, FALSE, FALSE, TRUE),
  final_state = c(
    "NOT_CREATED",
    "NOT_CREATED",
    "NOT_CREATED",
    "NONE",
    "EXITED; finalizer is nonpersistent and exits after manifest write"
  ),
  teardown_action = c(
    "NOT_APPLICABLE",
    "NOT_APPLICABLE",
    "NOT_APPLICABLE",
    "NOT_APPLICABLE",
    "NORMAL_PROCESS_EXIT"
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
write_evidence(teardown, "teardown_and_process_status.csv")

protection_summary <- data.frame(
  scope = c(
    "release manifest",
    "H07 execution inputs",
    "H07 preservation inventory",
    "accepted H07 PNG comparator",
    "accepted H01 S7-A SVG"
  ),
  rows_or_path = c(
    "123 rows",
    "39 rows",
    "1451 rows",
    "artifacts/08_figures/H07/H07_revised_smooth_derivative_pairs_near_eye.png",
    "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg"
  ),
  expected_sha256 = c(
    NA_character_,
    NA_character_,
    NA_character_,
    "f19763fe3c14c723ac38846bf735c0465ba2ee18765777a4f7304c677be71113",
    "4ddf972fc4c8082594d13a3b446537ae8a525ca35077e0605967f9c4c0ce519e"
  ),
  pre_status = "PASS",
  post_status = "PASS",
  unchanged = TRUE,
  stringsAsFactors = FALSE
)
write_evidence(protection_summary, "pre_post_protection_summary.csv")

handoff_lines <- c(
  "# REPORT-018 Order72j H07 component return",
  "",
  "Status: `CANDIDATE_PASS_AWAITING_INDEPENDENT_ACCEPTANCE`.",
  "",
  "Mandatory gate: `REPORT018-ORDER72J-COMPONENT-REVIEW`.",
  "",
  "## Authority",
  "",
  paste0("- Order SHA-256: `", authority$observed_sha256[[1L]], "`."),
  paste0("- Independent preflight acceptance SHA-256: `", authority$observed_sha256[[2L]], "`."),
  paste0("- Release manifest SHA-256: `", authority$observed_sha256[[3L]], "`, 123/123 live exact."),
  paste0("- H07 execution pins SHA-256: `", authority$observed_sha256[[4L]], "`, 39/39 live exact."),
  paste0("- H07 preservation inventory SHA-256: `", authority$observed_sha256[[5L]], "`, 1451/1451 live exact."),
  "",
  "## Candidate",
  "",
  paste0("- Path: `", substring(candidate_path, nchar(root) + 2L), "`."),
  paste0("- SHA-256: `", candidate_expected_sha256, "`."),
  paste0("- Bytes: `", candidate_expected_bytes, "`."),
  "- Native device: `svglite::svglite`, 9 by 18 inches.",
  "- One actual SVG export trial; zero renderer corrections.",
  "- Candidate and retained attempt are byte-identical.",
  "- Export implementation SHA-256: `08d9fe473b24374f2d6f569344adf7ae3835168253c7ceb18d07629fb859a34f`.",
  "",
  "## Frozen-source and static gates",
  "",
  "- Numerical input hashes pass 4/4: fitted smooth 918 rows, derivative 900 rows, qualifying transitions 12 rows across both panel kinds, and rugs 7011 rows.",
  "- Layer-to-row map passes 6/6. All source-row and built-row counts agree, with 18 ordered panels.",
  "- The nine manuscript metric labels and fitted-value-left, derivative-right order pass 18/18.",
  "- Derivative states remain 461 pointwise compatible with zero, 108 detected decreases, and 331 detected increases. Six near-eye metrics retain the derivative-defined plateau pattern and no row is non-estimable.",
  "- SVG XML and vector structure pass 16/16: 648 by 1296 points, matching the 9 by 18 inch canvas; no image, raster payload, script, foreign object or external resource; 37 unique IDs and 37/37 local references resolve.",
  "- Accepted visible text, pointwise qualification, internal title `Near-eye — primary`, palette, and privacy checks pass. No participant identifier occurs in visible text or SVG metadata.",
  "- The accepted PNG comparator and H01 S7-A SVG remain byte-exact under the pre/post inventories.",
  "",
  "## Attempt inventory",
  "",
  "Six construction/checker stops are preserved. Four occurred before any SVG device invocation, and two occurred only in the post-export static checker. None changed plot data, semantics or the SVG. The sole SVG export succeeded. Detailed causes and remedies are in `attempts/` and `evidence/attempt_inventory.csv`.",
  "",
  "## Visual QA and teardown",
  "",
  "The Harmonizer has not issued the serial visual-QA lease. Browser QA at original size, 170 mm and 708 px, plus comparison to the accepted PNG, is therefore `NOT_RUN`, not failed. No browser tab, loopback listener or serving root was created. No persistent task process remains, so teardown is not applicable.",
  "",
  "## Runtime and scope",
  "",
  "R 4.6.1 ran with `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` and the existing project R 4.6 library. Package and library identities are in `evidence/session_and_packages.csv`; exact command forms are in `evidence/command_inventory.csv`. No Quarto, Pandoc, Word or LibreOffice command ran. No model or RDS was loaded, and no fitting, prediction, derivative, interval, p-value, multiplicity, bootstrap, simulation or other scientific computation ran. No existing source, artifact, test, manifest, configuration, ledger or accepted figure was edited or replaced.",
  "",
  "The non-circular manifest covers every file in this new H07 owner root except itself. No promotion or downstream integration is authorized by this return."
)
assert_owner_target(handoff_path)
writeLines(handoff_lines, handoff_path, useBytes = TRUE)
stopifnot(file.exists(handoff_path), file.info(handoff_path)$size > 0)

all_owner_files <- list.files(
  owner_root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
all_owner_files <- all_owner_files[
  file.info(all_owner_files)$isdir %in% FALSE
]
all_owner_files <- sort(setdiff(
  normalizePath(all_owner_files, winslash = "/", mustWork = TRUE),
  normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
))
manifest <- data.frame(
  path = substring(all_owner_files, nchar(root) + 2L),
  sha256 = vapply(all_owner_files, sha256_file, character(1)),
  bytes = as.numeric(file.info(all_owner_files)$size),
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(manifest) > 0L,
  !anyDuplicated(manifest$path),
  !any(manifest$path == substring(manifest_path, nchar(root) + 2L))
)
assert_owner_target(manifest_path)
utils::write.csv(
  manifest,
  manifest_path,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

manifest_live <- readr::read_csv(manifest_path, show_col_types = FALSE)
current_files <- list.files(
  owner_root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
current_files <- current_files[file.info(current_files)$isdir %in% FALSE]
current_files <- sort(setdiff(
  normalizePath(current_files, winslash = "/", mustWork = TRUE),
  normalizePath(manifest_path, winslash = "/", mustWork = TRUE)
))
stopifnot(
  identical(manifest_live$path, substring(current_files, nchar(root) + 2L)),
  identical(
    manifest_live$sha256,
    vapply(current_files, sha256_file, character(1))
  ),
  all(manifest_live$bytes == as.numeric(file.info(current_files)$size)),
  !anyDuplicated(manifest_live$path)
)

cat(sprintf(
  paste0(
    "ORDER72J_H07_RETURN=CANDIDATE_PASS_AWAITING_INDEPENDENT_ACCEPTANCE ",
    "candidate=%s manifest=%s manifest_rows=%d visual_qa=NOT_RUN lease=NOT_ISSUED\n"
  ),
  candidate_expected_sha256,
  sha256_file(manifest_path),
  nrow(manifest_live)
))
