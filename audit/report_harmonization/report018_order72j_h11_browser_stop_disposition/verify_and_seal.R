stopifnot(getRversion() == numeric_version("4.6.1"))
project_root <- normalizePath(getwd(), mustWork = TRUE)
output_root <- file.path(
  project_root,
  "audit/report_harmonization/report018_order72j_h11_browser_stop_disposition"
)
stopifnot(dir.exists(output_root))
sha <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)
pin_rows <- data.frame(
  path = c(
    "audit/hypotheses/H11/report018_order72j_libreoffice_compatibility/qa/visual_lease_001_manifest.csv",
    "audit/hypotheses/H11/report018_order72j_libreoffice_compatibility/REPORT018-ORDER72J-COMPONENT-STOPPED.md",
    "audit/hypotheses/H11/report018_order72j_libreoffice_compatibility/qa/visual_lease_001_return.md",
    "audit/hypotheses/H11/report018_order72j_libreoffice_compatibility/manifest.csv",
    "audit/report_harmonization/report018_order72j_h11_static_independent_acceptance/manifest.csv",
    "audit/hypotheses/H11/report018_order72j_libreoffice_compatibility/candidate/H11_reader_near_eye_curves_arial_safe_margin.svg"
  ),
  sha256 = c(
    "546e387948c18b728c0810aa409324573b46b2fef9b6f724677876d8eb947281",
    "099ab3159afe3010394e0e2f095f7b718b9378e590ca65e4b8e78abed3e3f7fb",
    "b7240b7d00662afaf5898a917b29aeb13c344fad67303252cf00a3716d4ed076",
    "eb483dba0314be78780159ba96b16b98b8b00ad9f790d768064f83e56ce924c0",
    "0380aa97d71d44a34184c2ffda92741c56b67a3a2ad27754b53c2fc5f73eea7b",
    "ca613c8860b38625524518d106f0408ad264f90d78ef92bd9abd87f4daad904e"
  ),
  stringsAsFactors = FALSE
)
pin_rows$observed_sha256 <- vapply(file.path(project_root, pin_rows$path), sha, "")
stopifnot(all(pin_rows$sha256 == pin_rows$observed_sha256))
read_and_verify_manifest <- function(path, n) {
  rows <- read.csv(file.path(project_root, path), stringsAsFactors = FALSE)
  stopifnot(nrow(rows) == n, !anyDuplicated(rows$path))
  full <- ifelse(startsWith(rows$path, "/"), rows$path, file.path(project_root, rows$path))
  stopifnot(!any(normalizePath(full, mustWork = TRUE) == normalizePath(file.path(project_root, path))))
  observed <- vapply(full, sha, "")
  stopifnot(all(observed == rows$sha256))
  stopifnot(all(file.info(full)$size == rows$bytes))
  rows
}
qa_rows <- read_and_verify_manifest(pin_rows$path[[1]], 14L)
static_rows <- read_and_verify_manifest(pin_rows$path[[4]], 20L)
independent_rows <- read_and_verify_manifest(pin_rows$path[[5]], 30L)
write.csv(pin_rows, file.path(output_root, "control_pin_verification.csv"), row.names = FALSE)
checks <- data.frame(
  check = c("control_pins", "qa_members", "historical_static_members", "independent_static_members", "candidate_unchanged", "new_browser_action", "promotion"),
  expected = c("6/6", "14/14", "20/20", "30/30", "exact", "none", "none"),
  observed = c("6/6", "14/14", "20/20", "30/30", "exact", "none", "none"),
  status = "PASS"
)
write.csv(checks, file.path(output_root, "verification.csv"), row.names = FALSE)
writeLines(c(
  "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript --vanilla audit/report_harmonization/report018_order72j_h11_browser_stop_disposition/verify_and_seal.R",
  paste("digest:", as.character(packageVersion("digest"))),
  capture.output(sessionInfo())
), file.path(output_root, "session_and_command.txt"))
own_paths <- file.path(
  "audit/report_harmonization/report018_order72j_h11_browser_stop_disposition",
  c("disposition.md", "verify_and_seal.R", "control_pin_verification.csv", "verification.csv", "session_and_command.txt")
)
seal_paths <- sort(unique(c(own_paths, pin_rows$path, qa_rows$path)))
stopifnot(!anyDuplicated(seal_paths))
seal_full <- ifelse(startsWith(seal_paths, "/"), seal_paths, file.path(project_root, seal_paths))
seal <- data.frame(path = seal_paths, sha256 = vapply(seal_full, sha, ""), bytes = file.info(seal_full)$size)
manifest_path <- file.path(output_root, "manifest.csv")
stopifnot(!file.exists(manifest_path), !manifest_path %in% seal_full)
write.csv(seal, manifest_path, row.names = FALSE)
stopifnot(all(vapply(seal_full, sha, "") == seal$sha256))
cat("H11_BROWSER_STOP_DISPOSITION=PASS checks=7/7 qa=14/14 historical=20/20 independent=30/30 no_retry no_promotion\n")
cat("disposition_sha256=", sha(file.path(output_root, "disposition.md")), "\n", sep = "")
cat("manifest_rows=", nrow(seal), " manifest_sha256=", sha(manifest_path), "\n", sep = "")
