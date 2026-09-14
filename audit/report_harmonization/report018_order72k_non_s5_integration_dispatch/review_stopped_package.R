options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
resolve <- function(path) if (startsWith(path, "/")) path else file.path(root, path)
results <- list()
check <- function(name, passed, detail) {
  results[[length(results) + 1L]] <<- data.frame(check = name,
    status = if (isTRUE(passed)) "PASS" else "FAIL", detail = detail)
}
verify_manifest <- function(path, expected_sha, expected_rows, label) {
  stopifnot(sha(path) == expected_sha)
  pins <- read.csv(path, check.names = FALSE)
  paths <- vapply(pins$path, resolve, character(1))
  observed <- unname(vapply(paths, sha, character(1)))
  bytes <- as.numeric(file.info(paths)$size)
  check(label, nrow(pins) == expected_rows && !anyDuplicated(pins$path) &&
    !normalizePath(path) %in% normalizePath(paths) &&
    all(observed == pins$sha256) && all(bytes == pins$bytes),
    paste(expected_rows, "manifest rows rehashed against expected SHA-256 and bytes"))
  data.frame(manifest = label, path = pins$path, expected_sha256 = pins$sha256,
    observed_sha256 = observed, expected_bytes = pins$bytes, observed_bytes = bytes)
}
package <- verify_manifest(file.path(owner, "stopped_owner_manifest.csv"),
  "445ba04dd59cd3ef1be2d1d7bc625c8b4f8ce3852b97d48a9d80f86c3f667d25", 263L, "stopped_package_263")
base <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_release")
authority <- list(
  verify_manifest(file.path(base, "release_manifest.csv"), "07ca15e8d42663c12a2ce5d1ea5d724ee7ecf7480efe2e767654061b8ab9433d", 216L, "original_release_216"),
  verify_manifest(file.path(base, "integration_input_pins.csv"), "af995052b2c58e531a1e710a09942dcee275aca93433aff3d89533ce52b2c340", 186L, "original_inputs_186"),
  verify_manifest(file.path(base, "dispatch_manifest.csv"), "c1f3921d85b83f6adee86362c7d16730e7a8c8a576ee6bde34d36fbc215fa8f1", 6L, "original_dispatch_6"),
  verify_manifest(file.path(out, "dependency_closure_pins.csv"), "c43661fc9595057ead1272b9d02a9750c32a43484e4584d6c8d0b3a9fa36a88f", 21L, "direct_dependencies_21"))
seal <- jsonlite::fromJSON(file.path(owner, "stopped_owner_seal.json"))
check("stopped_note_identity", sha(seal$return_note$path) == "7e45b0b3398f9c3d6abcbb8ef6880329a2f48f1390b032ed6ba6e86804dc9d46", "Writer return note matches delivered identity")
check("main_html_identity", sha(seal$main_html$path) == "5e6c34d6fbcf8ecdd0093514268443eff6835e56e4ffc16e335fa545e62246f8", "Initial manuscript HTML, not a corrected or final preview")
check("selection_html_identity", sha(seal$selection_html$path) == "1369a47617daa95ddb66fab443bc3553225893fb73e4f9fd1810cc78effb43e0", "Initial selection HTML, not a corrected or final preview")
check("stopped_not_promoted", identical(seal$status, "STOPPED_ENVIRONMENT") && identical(seal$canonical_promotion, FALSE), "No final acceptance or canonical promotion claimed")
for (spec in list(
  list(file = "resource_copy_identities.csv", count = 138L, target = "copy"),
  list(file = "lua_copy_identities.csv", count = 3L, target = "copy"),
  list(file = "served_output_identities.csv", count = 12L, target = "served"))) {
  d <- read.csv(file.path(owner, "stopped_final_checks", spec$file), check.names = FALSE)
  left <- unname(vapply(d$source, sha, character(1)))
  right <- unname(vapply(d[[spec$target]], sha, character(1)))
  check(spec$file, nrow(d) == spec$count && all(left == d$sha256) && all(right == d$sha256),
    paste(spec$count, "source-to-copy byte identities independently rehashed"))
}
qmd <- read.csv(file.path(owner, "stopped_final_checks/unchanged_candidate_qmds.csv"))
check("candidate_qmd_3", nrow(qmd) == 3L && all(unname(vapply(vapply(qmd$path, resolve, character(1)), sha, character(1))) == qmd$sha256), "All three candidate authoring sources match stopped-state pins")
svg <- jsonlite::fromJSON(file.path(owner, "expanded_svg_manifest.json"))$accepted_figures
check("svg_map_22_sources_23_appearances", nrow(svg) == 22L && length(unique(svg$sha256)) == 22L && sum(svg$appearances) == 23L &&
    all(unname(vapply(svg$path, sha, character(1))) == svg$sha256) &&
    all(unname(vapply(vapply(svg$source_path, resolve, character(1)), sha, character(1))) == svg$sha256),
  "Frozen source/copy SVG identities and structural appearance mapping; historical S5 remains held")
check("table3_protected", sha(file.path(root, "audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html")) ==
  "d50b25afae95a95d61641349116e504a2bbf06780b43a46b195ac468246e8dc2", "Approved Table 3 exact bytes, including Descriptives ordering")
check("s2_failed_output_absent", !dir.exists(file.path(owner, "capture_s2_attempt2")), "No correction capture output is claimed")
docx_files <- list.files(owner, pattern = "\\.docx$", recursive = TRUE, full.names = TRUE)
check("no_new_manuscript_docx", !any(grepl("ZaunerEtAl2026_NatHealth.*\\.docx$", basename(docx_files))), "No Order72k manuscript DOCX exists; copied reference DOCX is not counted as an output")
teardown <- jsonlite::fromJSON(file.path(owner, "teardown_receipt.json"))
check("lease_release_recorded", identical(teardown$lease, "ORDER72K-VISUAL-LEASE-001") &&
  identical(teardown$disposition, "released with consolidated stopped return") &&
  identical(teardown$task_browser_tab$closed, TRUE) && identical(teardown$task_browser_tab$viewport_reset, TRUE),
  "Explicit Writer teardown record; no Harmonizer browser/native-app inspection performed")
checks <- do.call(rbind, results)
write.csv(checks, file.path(out, "stopped_independent_checks.csv"), row.names = FALSE)
write.csv(rbind(package, do.call(rbind, authority)), file.path(out, "stopped_independent_rehash.csv"), row.names = FALSE)
writeLines(c(
  "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/review_stopped_package.R",
  capture.output(sessionInfo())), file.path(out, "stopped_independent_session.txt"))
print(checks[c("check", "status")], row.names = FALSE)
stopifnot(all(checks$status == "PASS"))
