#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(digest))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
package_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72f_standalone_output_recovery"
)
owner_root <- file.path(
  root,
  "audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11"
)
recovery_root <- file.path(owner_root, "order72f_recovery")

sha256_file <- function(path) {
  if (!file.exists(path)) return(NA_character_)
  digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

check_manifest <- function(name) {
  manifest_path <- file.path(package_root, name)
  manifest <- read.csv(manifest_path, check.names = FALSE, stringsAsFactors = FALSE)
  observed_sha256 <- vapply(manifest$path, sha256_file, character(1))
  observed_bytes <- as.numeric(file.info(manifest$path)$size)
  data.frame(
    manifest = name,
    path = manifest$path,
    expected_sha256 = manifest$sha256,
    observed_sha256 = observed_sha256,
    expected_bytes = as.numeric(manifest$bytes),
    observed_bytes = observed_bytes,
    pass = observed_sha256 == manifest$sha256 &
      observed_bytes == as.numeric(manifest$bytes),
    stringsAsFactors = FALSE
  )
}

release <- check_manifest("release_manifest.csv")
pins <- check_manifest("current_execution_pins.csv")
manifest_checks <- rbind(release, pins)
write.csv(
  manifest_checks,
  file.path(recovery_root, "pre_render_manifest_checks.csv"),
  row.names = FALSE,
  na = ""
)

candidate_sibling <- file.path(
  root,
  "audit/manuscript_nature_health/manuscript_figure_table_selection_order72f_candidate.html"
)
candidate_support <- sub("[.]html$", "_files", candidate_sibling)
rendered_destination <- file.path(
  owner_root,
  "rendered/manuscript_figure_table_selection.html"
)
location_checks <- data.frame(
  path = c(candidate_sibling, candidate_support, rendered_destination),
  expected = "absent",
  observed = ifelse(file.exists(c(candidate_sibling, candidate_support, rendered_destination)), "present", "absent"),
  pass = !file.exists(c(candidate_sibling, candidate_support, rendered_destination)),
  stringsAsFactors = FALSE
)
write.csv(
  location_checks,
  file.path(recovery_root, "pre_render_location_checks.csv"),
  row.names = FALSE,
  na = ""
)

summary_checks <- data.frame(
  check = c(
    "release_manifest_rows_unique_exact",
    "current_execution_pins_rows_unique_exact",
    "candidate_locations_absent"
  ),
  observed = c(
    paste(nrow(release), anyDuplicated(release$path), sum(release$pass), sep = ";"),
    paste(nrow(pins), anyDuplicated(pins$path), sum(pins$pass), sep = ";"),
    paste(location_checks$observed, collapse = ";")
  ),
  expected = c("91;0;91", "78;0;78", "absent;absent;absent"),
  pass = c(
    nrow(release) == 91L && !anyDuplicated(release$path) && all(release$pass),
    nrow(pins) == 78L && !anyDuplicated(pins$path) && all(pins$pass),
    all(location_checks$pass)
  ),
  stringsAsFactors = FALSE
)
write.csv(
  summary_checks,
  file.path(recovery_root, "pre_render_checks.csv"),
  row.names = FALSE,
  na = ""
)

if (!all(summary_checks$pass)) {
  stop(
    "Order 72f pre-render checks failed: ",
    paste(summary_checks$check[!summary_checks$pass], collapse = ", ")
  )
}

cat("ORDER72F_PREFLIGHT=PASS R=", as.character(getRversion()), "\n", sep = "")
