options(warn = 1)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order72j visual-stop sealing requires R 4.6.1", call. = FALSE)
}
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("The pinned digest package is required", call. = FALSE)
}

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
output_root <- file.path(
  project_root,
  "audit/hypotheses/H11/report018_order72j_libreoffice_compatibility"
)
historical_manifest_path <- file.path(output_root, "manifest.csv")
candidate_path <- file.path(
  output_root,
  "candidate/H11_reader_near_eye_curves_arial_safe_margin.svg"
)
source_path <- file.path(
  project_root,
  "audit/hypotheses/H11/report018_order72_svg_export/candidate",
  "H11_reader_primary_near_eye_curves.svg"
)
lease_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_order72j_component_exports_dispatch",
  "visual_lease_001.csv"
)
input_pin_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_order72j_component_exports_release",
  "H11_execution_input_pins.csv"
)
preservation_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_order72j_component_exports_release",
  "H11_preservation_inventory.csv"
)
release_manifest_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_order72j_component_exports_release",
  "release_manifest.csv"
)
static_acceptance_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_order72j_h11_static_independent_acceptance",
  "acceptance.md"
)
static_acceptance_manifest_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_order72j_h11_static_independent_acceptance",
  "manifest.csv"
)
qa_dir <- file.path(output_root, "qa")
evidence_dir <- file.path(output_root, "evidence")
qa_manifest_path <- file.path(qa_dir, "visual_lease_001_manifest.csv")
visual_return_path <- file.path(qa_dir, "visual_lease_001_return.md")
stopped_path <- file.path(
  output_root,
  "REPORT018-ORDER72J-COMPONENT-STOPPED.md"
)

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

write_csv <- function(data, path) {
  utils::write.csv(data, path, row.names = FALSE, na = "")
}

verify_inventory <- function(path, expected_rows, label) {
  inventory <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (!identical(names(inventory), c("path", "sha256", "bytes")) ||
      nrow(inventory) != expected_rows || anyDuplicated(inventory$path) ||
      !all(file.exists(inventory$path))) {
    stop(paste("Invalid", label, "inventory structure"), call. = FALSE)
  }
  inventory$actual_sha256 <- unname(vapply(
    inventory$path,
    sha256_file,
    character(1)
  ))
  inventory$actual_bytes <- unname(as.numeric(file.info(inventory$path)$size))
  inventory$status <- ifelse(
    inventory$actual_sha256 == inventory$sha256 &
      inventory$actual_bytes == as.numeric(inventory$bytes),
    "PASS",
    "FAIL"
  )
  if (any(inventory$status != "PASS")) {
    stop(paste(label, "inventory drifted after visual attempt"), call. = FALSE)
  }
  inventory
}

required <- c(
  candidate_path,
  source_path,
  lease_path,
  input_pin_path,
  preservation_path,
  release_manifest_path,
  historical_manifest_path,
  static_acceptance_path,
  static_acceptance_manifest_path
)
if (!all(file.exists(required))) {
  stop("A required visual-stop control file is missing", call. = FALSE)
}
if (file.exists(stopped_path) || file.exists(qa_manifest_path) ||
    file.exists(visual_return_path)) {
  stop("Visual-stop evidence already exists; refusing to overwrite it", call. = FALSE)
}
if (!identical(
  sha256_file(historical_manifest_path),
  "eb483dba0314be78780159ba96b16b98b8b00ad9f790d768064f83e56ce924c0"
) || !identical(
  sha256_file(static_acceptance_path),
  "da00f89a94d4e64acaacdae65a5510f60378e1b6015f27c7a0306cf721781550"
) || !identical(
  sha256_file(static_acceptance_manifest_path),
  "0380aa97d71d44a34184c2ffda92741c56b67a3a2ad27754b53c2fc5f73eea7b"
)) {
  stop("Historical owner seal or independent static acceptance changed", call. = FALSE)
}

candidate_sha256 <- sha256_file(candidate_path)
source_sha256 <- sha256_file(source_path)
if (!identical(
  candidate_sha256,
  "ca613c8860b38625524518d106f0408ad264f90d78ef92bd9abd87f4daad904e"
) || !identical(
  source_sha256,
  "ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe"
)) {
  stop("Accepted or candidate SVG identity changed", call. = FALSE)
}

lease <- utils::read.csv(
  lease_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
h11_lease <- lease[
  lease$lease_id == "ORDER72J-VISUAL-LEASE-001" & lease$owner == "H11",
  ,
  drop = FALSE
]
if (nrow(h11_lease) != 1L || h11_lease$state[[1L]] != "ACTIVE") {
  stop("The exclusive H11 visual lease is absent or inactive", call. = FALSE)
}

post_release <- verify_inventory(
  release_manifest_path,
  123L,
  "release manifest"
)
post_inputs <- verify_inventory(input_pin_path, 34L, "H11 input pin")
post_preservation <- verify_inventory(
  preservation_path,
  531L,
  "H11 preservation"
)
historical_owner <- verify_inventory(
  historical_manifest_path,
  20L,
  "historical owner"
)

control_paths <- c(
  source_path,
  candidate_path,
  lease_path,
  input_pin_path,
  preservation_path,
  release_manifest_path,
  historical_manifest_path,
  static_acceptance_path,
  static_acceptance_manifest_path
)
control <- data.frame(
  role = c(
    "accepted_S17",
    "compatibility_candidate",
    "visual_lease_001",
    "H11_execution_input_pins",
    "H11_preservation_inventory",
    "release_manifest",
    "historical_owner_manifest_20",
    "independent_static_acceptance",
    "independent_static_acceptance_manifest_30"
  ),
  path = substring(control_paths, nchar(project_root) + 2L),
  sha256 = c(
    source_sha256,
    candidate_sha256,
    sha256_file(lease_path),
    sha256_file(input_pin_path),
    sha256_file(preservation_path),
    sha256_file(release_manifest_path),
    sha256_file(historical_manifest_path),
    sha256_file(static_acceptance_path),
    sha256_file(static_acceptance_manifest_path)
  ),
  bytes = unname(as.numeric(file.info(control_paths)$size)),
  status = "PASS",
  stringsAsFactors = FALSE
)

visual_checks <- data.frame(
  check = c(
    "direct_immutable_svg_route",
    "accepted_svg_loaded",
    "candidate_svg_loaded",
    "intrinsic_size_comparison",
    "642_css_px_comparison",
    "708_px_comparison",
    "panel_visibility",
    "scientific_geometry_and_content_identity",
    "arial_rendering",
    "note_containment",
    "essential_text_legibility",
    "renderer_differences"
  ),
  status = c(
    "BLOCKED_BY_BROWSER_URL_POLICY",
    rep("NOT_TESTED_BROWSER_ROUTE_BLOCKED", 11L)
  ),
  detail = c(
    paste(
      "The in-app browser rejected the direct file URL before document load;",
      "Order72j prohibits an alternate browser or loopback workaround after",
      "a rejected route."
    ),
    "No accepted SVG document loaded.",
    "No candidate SVG document loaded.",
    "Not tested.",
    "Not tested.",
    "Not tested.",
    "Not tested.",
    "Static identity checks remain PASS; visual identity was not tested.",
    "Not tested.",
    "Not tested.",
    "Not tested.",
    "Not tested."
  ),
  stringsAsFactors = FALSE
)

cleanup <- data.frame(
  check = c(
    "task_created_document_tab",
    "rejected_blank_tab_cleanup",
    "task_created_listener",
    "listener_teardown",
    "alternate_browser_or_loopback_attempt",
    "candidate_mutation_after_static_completion",
    "correction_trial_consumed",
    "promotion_attempted"
  ),
  status = c(
    "NONE",
    "PASS_CLOSED",
    "NONE",
    "NOT_APPLICABLE_NO_LISTENER_CREATED",
    "NONE",
    "NONE",
    "NONE",
    "NONE"
  ),
  detail = c(
    "The rejected navigation did not create a document-bearing SVG tab.",
    "The task-created about:blank tab from the rejected navigation was closed.",
    "No loopback or other listener was started.",
    "No listener existed to stop.",
    "Stopped after the browser-policy rejection as Order72j requires.",
    paste("Candidate remains", candidate_sha256),
    "No SVG correction was made.",
    "Candidate remains unpromoted."
  ),
  stringsAsFactors = FALSE
)

write_csv(
  control,
  file.path(evidence_dir, "post_visual_lease_001_control_identities.csv")
)
write_csv(
  post_release,
  file.path(evidence_dir, "post_visual_lease_001_release_rehash_123.csv")
)
write_csv(
  post_inputs,
  file.path(evidence_dir, "post_visual_lease_001_input_rehash_34.csv")
)
write_csv(
  post_preservation,
  file.path(evidence_dir, "post_visual_lease_001_preservation_rehash_531.csv")
)
write_csv(
  historical_owner,
  file.path(evidence_dir, "post_visual_lease_001_historical_owner_rehash_20.csv")
)
write_csv(
  visual_checks,
  file.path(qa_dir, "visual_lease_001_browser_checks.csv")
)
write_csv(
  cleanup,
  file.path(qa_dir, "visual_lease_001_cleanup.csv")
)
write_csv(
  data.frame(
    lease_id = "ORDER72J-VISUAL-LEASE-001",
    lease_status_observed = "ACTIVE",
    visual_disposition = "STOPPED_BROWSER_ROUTE_REJECTED",
    mandatory_gate = "REPORT018-ORDER72J-COMPONENT-REVIEW",
    candidate_status = "UNPROMOTED_STATIC_CANDIDATE_RETAINED",
    lease_release_requested = TRUE,
    stringsAsFactors = FALSE
  ),
  file.path(qa_dir, "visual_lease_001_disposition.csv")
)

writeLines(
  c(
    paste("R", as.character(getRversion())),
    "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
    paste("R_LIBS_USER", Sys.getenv("R_LIBS_USER")),
    ".libPaths():",
    .libPaths()
  ),
  file.path(evidence_dir, "visual_stop_runtime.txt"),
  useBytes = TRUE
)
writeLines(
  capture.output(sessionInfo()),
  file.path(evidence_dir, "visual_stop_session_info.txt"),
  useBytes = TRUE
)
writeLines(
  paste(
    "env RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
    paste0("R_LIBS_USER=", Sys.getenv("R_LIBS_USER")),
    "Rscript --vanilla",
    "audit/hypotheses/H11/report018_order72j_libreoffice_compatibility/code/finalize_visual_lease_001_stop.R"
  ),
  file.path(evidence_dir, "visual_stop_command.txt"),
  useBytes = TRUE
)

stopped <- c(
  "# REPORT018-ORDER72J-COMPONENT-REVIEW",
  "",
  "Status: **STOPPED**",
  "",
  "Visual disposition: **STOPPED_BROWSER_ROUTE_REJECTED**",
  "",
  paste("Candidate SHA-256:", candidate_sha256),
  paste("Accepted source SHA-256:", source_sha256),
  "",
  paste(
    "The exclusive H11 visual lease was active, but the in-app browser",
    "rejected the direct immutable file URL before either SVG loaded."
  ),
  paste(
    "Order72j requires a stopped QA return after a rejected browser route.",
    "No loopback, alternate browser, Word, LibreOffice, raster, correction,",
    "or promotion attempt followed."
  ),
  "",
  paste(
    "The task-created blank tab was closed. No listener was created. The",
    "candidate, 34 live H11 input pins, 531 preservation rows, and 123 release",
    "rows rehash exactly after the blocked review."
  ),
  "",
  "The compatibility candidate remains unpromoted. Visual improvement and",
  "non-regression are not established. Release the H11 visual lease."
)
writeLines(stopped, stopped_path, useBytes = TRUE)

visual_return <- c(
  "# REPORT018-ORDER72J-COMPONENT-REVIEW",
  "",
  "Status: **STOPPED**",
  "",
  "Visual disposition: **STOPPED_BROWSER_ROUTE_REJECTED**",
  "",
  paste("Candidate:", substring(candidate_path, nchar(project_root) + 2L)),
  paste("Candidate SHA-256:", candidate_sha256),
  paste("Accepted source SHA-256:", source_sha256),
  "",
  paste(
    "The candidate previously passed all static structure, inverse-mutation,",
    "and preservation checks. The issued visual lease was consumed only for",
    "one direct immutable file-URL attempt."
  ),
  paste(
    "That route was rejected by browser policy before either SVG loaded.",
    "Per Order72j, no alternate browser or loopback workaround was attempted."
  ),
  paste(
    "The task-created blank tab was closed, no listener was created, and the",
    "post-attempt candidate and all live protection inventories rehash exactly."
  ),
  "",
  paste(
    "No intrinsic, 642-pixel, or 708-pixel visual comparison was possible.",
    "Arial rendering, note containment, text legibility, and renderer",
    "differences remain not tested."
  ),
  "",
  paste(
    "No Word, LibreOffice, raster, correction-trial, or promotion work was",
    "performed. The static candidate remains unpromoted. Release the H11",
    "visual lease."
  )
)
writeLines(visual_return, visual_return_path, useBytes = TRUE)

qa_manifest_members <- c(
  file.path(output_root, "code/finalize_visual_lease_001_stop.R"),
  file.path(evidence_dir, "post_visual_lease_001_control_identities.csv"),
  file.path(evidence_dir, "post_visual_lease_001_release_rehash_123.csv"),
  file.path(evidence_dir, "post_visual_lease_001_input_rehash_34.csv"),
  file.path(evidence_dir, "post_visual_lease_001_preservation_rehash_531.csv"),
  file.path(evidence_dir, "post_visual_lease_001_historical_owner_rehash_20.csv"),
  file.path(evidence_dir, "visual_stop_runtime.txt"),
  file.path(evidence_dir, "visual_stop_session_info.txt"),
  file.path(evidence_dir, "visual_stop_command.txt"),
  file.path(qa_dir, "visual_lease_001_browser_checks.csv"),
  file.path(qa_dir, "visual_lease_001_cleanup.csv"),
  file.path(qa_dir, "visual_lease_001_disposition.csv"),
  visual_return_path,
  stopped_path
)
if (!all(file.exists(qa_manifest_members)) || anyDuplicated(qa_manifest_members)) {
  stop("The visual-stop QA evidence set is incomplete or duplicated", call. = FALSE)
}
qa_manifest <- data.frame(
  path = substring(qa_manifest_members, nchar(project_root) + 2L),
  sha256 = unname(vapply(qa_manifest_members, sha256_file, character(1))),
  bytes = unname(as.numeric(file.info(qa_manifest_members)$size)),
  stringsAsFactors = FALSE
)
if (anyDuplicated(qa_manifest$path) || qa_manifest_path %in% qa_manifest_members) {
  stop("Non-circular visual-stop manifest construction failed", call. = FALSE)
}
write_csv(qa_manifest, qa_manifest_path)

if (!identical(
  sha256_file(historical_manifest_path),
  "eb483dba0314be78780159ba96b16b98b8b00ad9f790d768064f83e56ce924c0"
) || !identical(sha256_file(candidate_path), candidate_sha256)) {
  stop("Historical owner seal or candidate changed while sealing QA", call. = FALSE)
}

cat(
  paste0(
    "STOPPED_BROWSER_ROUTE_REJECTED ",
    "candidate_sha256=", candidate_sha256,
    " qa_manifest_sha256=", sha256_file(qa_manifest_path),
    " qa_manifest_rows=", nrow(qa_manifest),
    "\n"
  )
)
