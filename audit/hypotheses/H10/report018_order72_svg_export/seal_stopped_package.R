#!/usr/bin/env Rscript

# Seal the fail-closed H10 Order 72 package after the single QA run stopped.
# This script hashes files only. It does not retry export, SVG QA, or raster QA.

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(sprintf("Stopped seal requires R 4.6.1; running %s", getRversion()), call. = FALSE)
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
sha256_file <- function(path) digest::digest(file = path, algo = "sha256")

output_relative <- "audit/hypotheses/H10/report018_order72_svg_export"
output_root <- file.path(root, output_relative)
post_pin_path <- file.path(output_root, "post_stop_pin_audit.csv")
manifest_path <- file.path(output_root, "stopped_manifest.csv")
if (file.exists(post_pin_path) || file.exists(manifest_path)) {
  stop("Refusing to overwrite a stopped-seal output", call. = FALSE)
}

release_relative <- paste0(
  "audit/report_harmonization/report018_order72_release/",
  "release_manifest.csv"
)
release_path <- file.path(root, release_relative)
if (!identical(
  sha256_file(release_path),
  "8e25aa779f0115a3a5da9ffcdc3913b81cd6fb06df0c17c9f6d5825356263526"
)) {
  stop("Release manifest drifted before stopped-package sealing", call. = FALSE)
}
release <- read.csv(release_path, stringsAsFactors = FALSE, check.names = FALSE)
if (
  !identical(names(release), c("path", "sha256", "bytes")) ||
    nrow(release) != 71L ||
    anyDuplicated(release$path) ||
    !all(file.exists(file.path(root, release$path)))
) {
  stop("Release manifest schema, uniqueness, or existence check failed", call. = FALSE)
}
observed_hash <- vapply(
  file.path(root, release$path),
  sha256_file,
  character(1)
)
observed_bytes <- unname(file.info(file.path(root, release$path))$size)
post_pins <- data.frame(
  path = release$path,
  expected_sha256 = release$sha256,
  observed_sha256 = observed_hash,
  expected_bytes = release$bytes,
  observed_bytes = observed_bytes,
  status = ifelse(
    release$sha256 == observed_hash & release$bytes == observed_bytes,
    "PASS",
    "FAIL"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
if (!all(post_pins$status == "PASS")) {
  print(post_pins[post_pins$status != "PASS", , drop = FALSE])
  stop("A released identity drifted before stopped-package sealing", call. = FALSE)
}
write.csv(post_pins, post_pin_path, row.names = FALSE, na = "")

reference_paths <- c(
  "audit/report_harmonization/owner_orders/72_manuscript_svg_exports_released.md",
  "audit/report_harmonization/owner_orders/72_manuscript_svg_exports_proposed.md",
  release_relative,
  "audit/manuscript_nature_health/figure_table_selection_assets/H10_age_site_significant_associations_selection_candidate.png",
  "artifacts/10_figures/H10/H10_age_site_significant_associations.pdf",
  "artifacts/11_source_data/H10/H10_age_site_significant_associations_data.csv",
  "audit/hypotheses/H10/manuscript_selection_figure_candidate/candidate_display_text.csv",
  "audit/hypotheses/H10/manuscript_selection_figure_candidate/build_h10_selection_figure_candidate.R"
)
package_paths <- sort(list.files(
  output_root,
  recursive = TRUE,
  full.names = FALSE,
  include.dirs = FALSE
))
package_paths <- file.path(output_relative, package_paths)
if (manifest_path %in% file.path(root, package_paths)) {
  stop("Circular stopped manifest membership detected", call. = FALSE)
}
members <- unique(c(reference_paths, package_paths))
member_abs <- file.path(root, members)
if (!all(file.exists(member_abs))) {
  stop("A stopped-manifest member is absent", call. = FALSE)
}
manifest <- data.frame(
  path = members,
  role = c(
    rep("frozen reference", length(reference_paths)),
    rep("stopped H10 Order 72 evidence", length(setdiff(package_paths, reference_paths)))
  ),
  sha256 = vapply(member_abs, sha256_file, character(1)),
  bytes = unname(file.info(member_abs)$size),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
if (nrow(manifest) != length(members) || anyDuplicated(manifest$path)) {
  stop("Stopped manifest is not exact and unique", call. = FALSE)
}
write.csv(manifest, manifest_path, row.names = FALSE, na = "")

sealed <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
sealed_abs <- file.path(root, sealed$path)
if (
  anyDuplicated(sealed$path) ||
    any(sealed$path == file.path(output_relative, "stopped_manifest.csv")) ||
    !all(file.exists(sealed_abs)) ||
    !all(vapply(sealed_abs, sha256_file, character(1)) == sealed$sha256) ||
    !all(unname(file.info(sealed_abs)$size) == sealed$bytes)
) {
  stop("Stopped package did not verify after sealing", call. = FALSE)
}

message(
  "REPORT018_ORDER72_H10_STOPPED_SEAL_PASS release=71/71 manifest=",
  nrow(sealed),
  "/",
  nrow(sealed),
  " non-circular"
)
